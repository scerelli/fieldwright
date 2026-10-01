import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/app.dart';
import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/correction.dart';
import 'package:ibis/features/visits/visit_detail_screen.dart';
import 'package:ibis/features/visits/visit_status.dart';
import 'package:ibis/features/visits/visits_client.dart';
import 'package:ibis/features/visits/visits_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/router/app_router.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

/// A [VisitsClient] that answers from memory, so no request leaves the process.
class _FakeVisitsClient extends VisitsClient {
  _FakeVisitsClient({
    required this.status,
    this.corrections = const <Correction>[],
  }) : super(
         baseUrl: 'http://test.local',
         auth: AuthClient(baseUrl: 'http://test.local'),
       );

  final VisitStatus status;
  final List<Correction> corrections;

  @override
  Future<VisitStatus> readStatus(String visitId) async => status;

  @override
  Future<List<Correction>> listCorrections(String visitId) async => corrections;
}

AppDatabase _openDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

Site _site() => Site(
  id: 'site-1',
  projectId: 'project-1',
  geometry: const PointGeometry(LatLng(45.0, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

const VisitStatus _submitted = VisitStatus(
  state: VisitLifecycleState.submitted,
);

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

/// A router shaped like the app's `/visits` branch: the Visits list, with the
/// Visit detail as its `:visitId` child.
Widget _visitsShell(AppDatabase database, VisitsClient client) {
  final router = GoRouter(
    initialLocation: '/visits',
    routes: [
      GoRoute(
        path: '/visits',
        builder: (_, _) => const VisitsScreen(
          projectId: 'project-1',
          surveyPeriodId: 'survey-period-1',
          protocolVersionId: 'protocol-version-1',
        ),
        routes: [
          GoRoute(
            path: ':visitId',
            builder: (context, state) => VisitDetailScreen(
              visitId: state.pathParameters['visitId']!,
              client: client,
            ),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(database)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('VisitDetailScreen', () {
    testWidgets('shows a submitted Visit\'s Validation status', (tester) async {
      await tester.pumpWidget(
        _wrap(
          VisitDetailScreen(
            visitId: 'v1',
            client: _FakeVisitsClient(status: _submitted),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Submitted'), findsOneWidget);
    });

    testWidgets('shows a validated Visit\'s Validation status', (tester) async {
      await tester.pumpWidget(
        _wrap(
          VisitDetailScreen(
            visitId: 'v1',
            client: _FakeVisitsClient(
              status: VisitStatus(
                state: VisitLifecycleState.validated,
                validatorId: 'u1',
                validatedAt: DateTime.utc(2026, 9, 30, 12),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Validated'), findsOneWidget);
    });

    testWidgets('shows a rejected Visit\'s Validation status', (tester) async {
      await tester.pumpWidget(
        _wrap(
          VisitDetailScreen(
            visitId: 'v1',
            client: _FakeVisitsClient(
              status: VisitStatus(
                state: VisitLifecycleState.rejected,
                validatorId: 'u1',
                validatedAt: DateTime.utc(2026, 9, 30, 12),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('lists Corrections oldest-first, each with author and time', (
      tester,
    ) async {
      final corrections = <Correction>[
        Correction(
          authorId: 'u1',
          reason: 'wrong count',
          payload: const <String, dynamic>{},
          createdAt: DateTime.utc(2026, 9, 30, 10),
        ),
        Correction(
          authorId: 'u2',
          reason: 'wrong taxon',
          payload: const <String, dynamic>{},
          createdAt: DateTime.utc(2026, 9, 30, 11),
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          VisitDetailScreen(
            visitId: 'v1',
            client: _FakeVisitsClient(
              status: _submitted,
              corrections: corrections,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final first = tester.getTopLeft(find.text('u1'));
      final second = tester.getTopLeft(find.text('u2'));
      expect(first.dy, lessThan(second.dy));
      expect(find.text('2026-09-30T10:00:00.000Z'), findsOneWidget);
      expect(find.text('2026-09-30T11:00:00.000Z'), findsOneWidget);
    });

    testWidgets('shows an empty Corrections state when there are none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          VisitDetailScreen(
            visitId: 'v1',
            client: _FakeVisitsClient(status: _submitted),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This visit has no corrections.'), findsOneWidget);
    });
  });

  testWidgets('opening a Visit from the Visits screen shows its status', (
    tester,
  ) async {
    final database = _openDatabase();
    await SiteDao(database).save(_site());
    final visit = await VisitDao(database).startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
    );
    await VisitDao(database).endVisit(visit);

    await tester.pumpWidget(
      _visitsShell(database, _FakeVisitsClient(status: _submitted)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('visit_${visit.id}')));
    await tester.pumpAndSettle();

    expect(find.byType(VisitDetailScreen), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
  });

  testWidgets('the app router exposes the Visit detail route', (tester) async {
    final database = _openDatabase();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        visitsClientProvider.overrideWithValue(
          _FakeVisitsClient(status: _submitted),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const IbisApp()),
    );
    await tester.pumpAndSettle();

    router.go('/visits/v1');
    await tester.pumpAndSettle();

    expect(find.byType(VisitDetailScreen), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
  });
}
