import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/app.dart';
import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/auth/auth_provider.dart';
import 'package:ibis/features/account/account_screen.dart';
import 'package:ibis/features/projects/projects_screen.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/sites/sites_screen.dart';
import 'package:ibis/features/visits/visits_screen.dart';
import 'package:ibis/outbox/outbox.dart';
import 'package:ibis/router/app_router.dart';
import 'package:ibis/shell/app_shell.dart';
import 'package:ibis/shell/connectivity.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/outbox_dao.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

/// A [ConnectivitySource] double that reports a fixed offline state without a
/// platform channel, so the shell's offline and online states are testable.
class _FakeConnectivity implements ConnectivitySource {
  _FakeConnectivity({this.offline = false});

  final bool offline;

  @override
  Future<bool> isOffline() async => offline;

  @override
  Stream<bool> get offlineChanges => const Stream<bool>.empty();
}

/// An [Outbox] double that records flushes instead of touching the network, so
/// the shell's retry affordance is observable without a transport.
class _RecordingOutbox extends Outbox {
  _RecordingOutbox(super.dao);

  int flushes = 0;

  @override
  Future<void> flush({
    RetryPolicy retry = const RetryPolicy(),
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  }) async {
    flushes += 1;
  }
}

/// An [AuthController] that starts already signed in, so the shell's linked
/// states (syncing, failed) are reachable in a test without a sign-in flow.
class _SignedInAuthController extends AuthController {
  @override
  Person? build() =>
      const Person(id: 'p1', email: 'ada@example.org', name: 'Ada');
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  AppDatabase? database,
  ConnectivitySource? connectivity,
  Outbox? outbox,
  bool signedIn = false,
}) async {
  final db = database ?? AppDatabase(NativeDatabase.memory());
  if (database == null) addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      connectivitySourceProvider.overrideWithValue(
        connectivity ?? _FakeConnectivity(),
      ),
      if (outbox != null) outboxProvider.overrideWithValue(outbox),
      if (signedIn) authProvider.overrideWith(_SignedInAuthController.new),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const IbisApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

String currentPath(WidgetTester tester) =>
    GoRouterState.of(tester.element(find.byType(AppShell))).uri.path;

/// An ended Visit in the local store, so an outbox row can reference it.
Future<String> _endedVisitId(AppDatabase database) async {
  await SiteDao(database).save(
    Site(
      id: 'site-1',
      projectId: 'project-1',
      geometry: const PointGeometry(LatLng(45.0, 9.0)),
      origin: SiteOrigin.planned,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  final dao = VisitDao(database);
  final visit = await dao.startVisit(
    siteId: 'site-1',
    surveyPeriodId: 'survey-period-1',
    protocolVersionId: 'protocol-version-1',
  );
  return (await dao.endVisit(visit)).id;
}

void main() {
  group('connectivity_plus result mapping (ADR-0022)', () {
    test('an empty result list means offline', () {
      expect(hasNoConnection(const <ConnectivityResult>[]), isTrue);
    });

    test('a single none result means offline', () {
      expect(
        hasNoConnection(const <ConnectivityResult>[ConnectivityResult.none]),
        isTrue,
      );
    });

    test('a real transport alongside none means online', () {
      // The plugin only emits `none` alone, but a defensive mapping must treat
      // any real transport as a connection rather than treating the stray
      // `none` as authoritative.
      expect(
        hasNoConnection(const <ConnectivityResult>[
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        isFalse,
      );
      expect(
        hasNoConnection(const <ConnectivityResult>[ConnectivityResult.mobile]),
        isFalse,
      );
    });
  });

  testWidgets('the app opens on the Projects list at /projects', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(currentPath(tester), '/projects');
    expect(find.byType(ProjectsScreen), findsOneWidget);
  });

  testWidgets('the Projects list renders no bottom navigation bar', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Account opens from the app bar on the Projects list', (
    tester,
  ) async {
    await pumpApp(tester);

    final account = find.byKey(const Key('open_account'));
    expect(account, findsOneWidget);

    await tester.tap(account);
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/account');
    expect(find.byType(AccountScreen), findsOneWidget);
  });

  testWidgets('no top-level route lists Sites or Visits across Projects '
      '(UX-019)', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(goRouterProvider);

    router.go('/sites');
    await tester.pumpAndSettle();
    expect(find.byType(SitesScreen), findsNothing);

    router.go('/visits');
    await tester.pumpAndSettle();
    expect(find.byType(VisitsScreen), findsNothing);
  });

  testWidgets('the shell renders the system-state indicator on every route '
      '(UX-008)', (tester) async {
    final container = await pumpApp(tester);
    // A visible state key, not just the widget: the indicator renders nothing
    // when there is nothing to report, so by-type alone would not prove it.
    expect(find.byKey(const Key('shell_indicator_unlinked')), findsOneWidget);

    final router = container.read(goRouterProvider);
    router.go('/account');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shell_indicator_unlinked')), findsOneWidget);
    expect(find.byType(AccountScreen), findsOneWidget);

    router.go('/help');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shell_indicator_unlinked')), findsOneWidget);
  });

  testWidgets('the indicator shows the offline state when there is no '
      'connection (UX-007, UX-008)', (tester) async {
    await pumpApp(tester, connectivity: _FakeConnectivity(offline: true));

    expect(find.byKey(const Key('shell_indicator_offline')), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('the indicator shows the unlinked state while not signed in '
      '(UX-008, UX-016)', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('shell_indicator_unlinked')), findsOneWidget);
  });

  testWidgets('the indicator shows the syncing state while a submission is in '
      'flight (UX-008)', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final visitId = await _endedVisitId(database);
    final dao = OutboxDao(database);
    await dao.enqueue(visitId);
    await dao.setSyncState(visitId, SyncState.syncing);

    await pumpApp(tester, database: database);

    expect(find.byKey(const Key('shell_indicator_syncing')), findsOneWidget);
  });

  testWidgets(
    'the indicator shows the syncing state for a submission still queued once '
    'signed in (UX-008)',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visitId = await _endedVisitId(database);
      // Queued, not yet `syncing`: with a signed-in person the shell reports it
      // as in flight rather than falling through to the unlinked state.
      await OutboxDao(database).enqueue(visitId);

      await pumpApp(tester, database: database, signedIn: true);

      expect(find.byKey(const Key('shell_indicator_syncing')), findsOneWidget);
    },
  );

  testWidgets('the indicator clears the status-bar inset (UX-008)', (
    tester,
  ) async {
    const topInset = 40.0;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: topInset);
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    final indicatorTop = tester
        .getTopLeft(find.byKey(const Key('shell_indicator_unlinked')))
        .dy;
    expect(indicatorTop, greaterThanOrEqualTo(topInset));
    // The routed screen's own AppBar must clear the inset too, without a second
    // inset below the indicator: the shell owns the top inset once.
    final appBarTop = tester.getTopLeft(find.byType(AppBar).first).dy;
    expect(appBarTop, greaterThanOrEqualTo(topInset));
    expect(tester.getSize(find.byType(AppBar).first).height, 56);
  });

  testWidgets('the indicator follows a failed submission and offers retry '
      '(UX-008)', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final visitId = await _endedVisitId(database);
    await OutboxDao(database).enqueue(visitId);
    final outbox = _RecordingOutbox(OutboxDao(database));

    final container = await pumpApp(tester, database: database, outbox: outbox);
    // Write through the container's own DAO, so the summary stream the shell
    // watches is the one that re-emits (the shell is the only writer in the app).
    final dao = container.read(outboxDaoProvider);

    await dao.setSyncState(visitId, SyncState.syncing);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shell_indicator_syncing')), findsOneWidget);

    await dao.setSyncState(visitId, SyncState.failed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shell_indicator_failed')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shell_indicator_retry')));
    await tester.pumpAndSettle();
    expect(outbox.flushes, 1);
  });

  testWidgets('the system-state indicator is non-modal and never a dialog '
      '(UX-008)', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final visitId = await _endedVisitId(database);
    final dao = OutboxDao(database);
    await dao.enqueue(visitId);
    await dao.setSyncState(visitId, SyncState.failed);

    await pumpApp(tester, database: database);

    expect(find.byKey(const Key('shell_indicator_failed')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    // The routed screen beneath stays rendered: non-modal, never a dialog.
    expect(find.byType(ProjectsScreen), findsOneWidget);
  });
}
