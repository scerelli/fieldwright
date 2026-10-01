import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/outbox/outbox.dart';
import 'package:ibis/outbox/sync_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/outbox_dao.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';
import 'package:ibis/theme/app_theme.dart';
import 'package:ibis/widgets/sync_indicator.dart';

/// A [SyncClient] double that accepts every submission without a transport, so
/// a re-queue is observable as the Visit reaching `synced` inside the widget
/// test's fake-async zone.
class _DeliveringSyncClient extends SyncClient {
  _DeliveringSyncClient()
    : super(
        baseUrl: 'http://test.local',
        auth: AuthClient(baseUrl: 'http://test.local'),
      );

  @override
  Future<SubmitResult> submit(
    Visit visit, {
    required String projectId,
    DateTime? submittedAt,
  }) async => SubmitResult.delivered;
}

/// An outbox wired to a transport that accepts every submission.
Outbox _acceptingOutbox(AppDatabase database) => Outbox(
  OutboxDao(database),
  client: _DeliveringSyncClient(),
  visits: VisitDao(database),
  sites: SiteDao(database),
);

/// A [SyncClient] double whose submission is held until [gate] completes, so a
/// test can pin delivery open while the submit handler's first render lands and
/// then release it to prove the indicator follows the outcome. Without that
/// gate the untracked background flush could finish before the handler reads
/// the state, hiding the stale-indicator bug the test guards.
class _GatedSyncClient extends SyncClient {
  _GatedSyncClient(this.result)
    : super(
        baseUrl: 'http://test.local',
        auth: AuthClient(baseUrl: 'http://test.local'),
      );

  final SubmitResult result;
  final Completer<void> gate = Completer<void>();

  @override
  Future<SubmitResult> submit(
    Visit visit, {
    required String projectId,
    DateTime? submittedAt,
  }) async {
    await gate.future;
    return result;
  }
}

/// An outbox wired to [client], delivering only once the client's gate opens.
Outbox _gatedOutbox(AppDatabase database, _GatedSyncClient client) => Outbox(
  OutboxDao(database),
  client: client,
  visits: VisitDao(database),
  sites: SiteDao(database),
);

/// Whether the indicator currently renders an in-flight state — `queued` or
/// `syncing`. Which of the two a gated submit shows is timing-dependent, so the
/// tests accept either.
bool _isQueuedOrSyncing() =>
    find.byKey(const Key('sync_indicator_queued')).evaluate().isNotEmpty ||
    find.byKey(const Key('sync_indicator_syncing')).evaluate().isNotEmpty;

Site _site() => Site(
  id: 'site-1',
  projectId: 'project-1',
  geometry: const PointGeometry(LatLng(45.0, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

Future<Visit> _endedVisit(AppDatabase database) async {
  await SiteDao(database).save(_site());
  final dao = VisitDao(database);
  final visit = await dao.startVisit(
    siteId: 'site-1',
    surveyPeriodId: 'survey-period-1',
    protocolVersionId: 'protocol-version-1',
  );
  return dao.endVisit(visit);
}

Widget _host(AppDatabase database, Widget child) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('the indicator renders each of the Visit\'s sync states', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const labels = <SyncState, String>{
      SyncState.queued: 'Queued',
      SyncState.syncing: 'Syncing',
      SyncState.synced: 'Synced',
      SyncState.failed: 'Sync failed',
    };
    for (final state in SyncState.values) {
      await tester.pumpWidget(
        _host(database, SyncIndicatorView(state: state, onRetry: () {})),
      );
      await tester.pump();

      expect(
        find.byKey(Key('sync_indicator_${state.name}')),
        findsOneWidget,
        reason: 'expected the indicator to show $state',
      );
      expect(find.text(labels[state]!), findsOneWidget);
      expect(
        find.byKey(const Key('sync_indicator_retry')),
        state == SyncState.failed ? findsOneWidget : findsNothing,
      );
    }
  });

  testWidgets('the indicator shows the Visit\'s stored sync state', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final visit = await _endedVisit(database);
    final dao = OutboxDao(database);
    await dao.enqueue(visit.id);
    await dao.setSyncState(visit.id, SyncState.synced);

    await tester.pumpWidget(_host(database, SyncIndicator(visitId: visit.id)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sync_indicator_synced')), findsOneWidget);

    await dao.setSyncState(visit.id, SyncState.failed);
    ProviderScope.containerOf(
      tester.element(find.byType(SyncIndicator)),
    ).invalidate(visitSyncStateProvider(visit.id));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sync_indicator_failed')), findsOneWidget);
  });

  testWidgets('tapping retry on a failed submission re-queues the Visit', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final visit = await _endedVisit(database);
    final dao = OutboxDao(database);
    await dao.enqueue(visit.id);
    await dao.setSyncState(visit.id, SyncState.failed);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          outboxProvider.overrideWithValue(_acceptingOutbox(database)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CaptureScreen(visit: visit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sync_indicator_failed')), findsOneWidget);
    expect(await dao.syncStateOf(visit.id), SyncState.failed);

    await tester.tap(find.byKey(const Key('sync_indicator_retry')));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    expect(await dao.syncStateOf(visit.id), SyncState.synced);
    expect(
      (await VisitDao(database).findById(visit.id))!.state,
      VisitState.submitted,
    );
  });

  testWidgets(
    'submitting through the capture screen follows delivery to synced',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _endedVisit(database);
      final client = _GatedSyncClient(SubmitResult.delivered);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            outboxProvider.overrideWithValue(_gatedOutbox(database, client)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CaptureScreen(visit: visit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_visit')));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(
        find.byKey(const Key('sync_indicator_synced')),
        findsNothing,
        reason: 'delivery is still gated, so the Visit cannot be synced yet',
      );
      expect(
        _isQueuedOrSyncing(),
        isTrue,
        reason: 'the indicator follows delivery in place while it is queued',
      );

      client.gate.complete();
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      expect(find.byKey(const Key('sync_indicator_synced')), findsOneWidget);
      expect(await OutboxDao(database).syncStateOf(visit.id), SyncState.synced);
      expect(
        (await VisitDao(database).findById(visit.id))!.state,
        VisitState.submitted,
      );
    },
  );

  testWidgets(
    'a rejected submission renders failed and offers retry from the real '
    'submit handler',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _endedVisit(database);
      final client = _GatedSyncClient(SubmitResult.rejected);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            outboxProvider.overrideWithValue(_gatedOutbox(database, client)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CaptureScreen(visit: visit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_visit')));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(
        find.byKey(const Key('sync_indicator_failed')),
        findsNothing,
        reason: 'delivery is still gated, so the Visit cannot have failed yet',
      );
      expect(
        _isQueuedOrSyncing(),
        isTrue,
        reason: 'the indicator follows delivery in place while it is queued',
      );

      client.gate.complete();
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      expect(find.byKey(const Key('sync_indicator_failed')), findsOneWidget);
      expect(find.byKey(const Key('sync_indicator_retry')), findsOneWidget);
      expect(await OutboxDao(database).syncStateOf(visit.id), SyncState.failed);
    },
  );

  testWidgets(
    'leaving the screen mid-delivery does not throw from the submit handler',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _endedVisit(database);
      final client = _GatedSyncClient(SubmitResult.delivered);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            outboxProvider.overrideWithValue(_gatedOutbox(database, client)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CaptureScreen(visit: visit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_visit')));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      // Navigate away: the capture screen is disposed while delivery is still
      // in flight, so the submit handler's post-await invalidate must not touch
      // a disposed ref.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();

      client.gate.complete();
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'leaving the screen mid-retry does not throw from the retry handler',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _endedVisit(database);
      final dao = OutboxDao(database);
      await dao.enqueue(visit.id);
      await dao.setSyncState(visit.id, SyncState.failed);
      final client = _GatedSyncClient(SubmitResult.delivered);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            outboxProvider.overrideWithValue(_gatedOutbox(database, client)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CaptureScreen(visit: visit),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sync_indicator_failed')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sync_indicator_retry')));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();

      client.gate.complete();
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sync indicator golden in the light theme', (tester) async {
    await _pumpGolden(tester, buildLightTheme());
    await expectLater(
      find.byKey(const Key('sync_indicator_golden')),
      matchesGoldenFile('goldens/sync_indicator_light.png'),
    );
  });

  testWidgets('sync indicator golden in the dark theme', (tester) async {
    await _pumpGolden(tester, buildDarkTheme());
    await expectLater(
      find.byKey(const Key('sync_indicator_golden')),
      matchesGoldenFile('goldens/sync_indicator_dark.png'),
    );
  });
}

/// Renders every sync state inline in a screen body so the golden shows the
/// persistent, non-modal indicator and the `failed` state's error colour
/// (UX-008).
Future<void> _pumpGolden(WidgetTester tester, ThemeData theme) async {
  tester.view.physicalSize = const Size(360, 240);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          key: const Key('sync_indicator_golden'),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final state in SyncState.values)
                SyncIndicatorView(state: state, onRetry: () {}),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
