import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/detection.dart';
import 'package:ibis/features/visits/submission_readiness.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/features/visits/visits_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/projects/projects_client.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/theme/app_theme.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/project_dao.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

Site _site() => Site(
  id: 'site-1',
  projectId: 'project-1',
  geometry: const PointGeometry(LatLng(45.0, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

AppDatabase _openDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

Future<Visit> _submittedVisit(AppDatabase database) async {
  await SiteDao(database).save(_site());
  final dao = VisitDao(database);
  final visit = await dao.startVisit(
    siteId: 'site-1',
    surveyPeriodId: 'survey-period-1',
    protocolVersionId: 'protocol-version-1',
  );
  final ended = await dao.endVisit(visit);
  return dao.markSubmitted(ended.id);
}

Widget _app(AppDatabase database, Widget home) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

/// A routed capture screen whose needs-attention actions can navigate to the
/// Project's configuration surfaces, each stubbed with a marker.
Widget _routedCapture(AppDatabase database, Visit visit) {
  final router = GoRouter(
    initialLocation: '/capture',
    routes: <RouteBase>[
      GoRoute(
        path: '/capture',
        builder: (context, state) => CaptureScreen(visit: visit),
      ),
      GoRoute(
        path: '/projects/:projectId/protocol',
        builder: (context, state) =>
            const Scaffold(body: Text('protocol-surface')),
      ),
      GoRoute(
        path: '/projects/:projectId/survey-periods',
        builder: (context, state) =>
            const Scaffold(body: Text('survey-periods-surface')),
      ),
      GoRoute(
        path: '/projects/:projectId/settings',
        builder: (context, state) =>
            const Scaffold(body: Text('settings-surface')),
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

Future<Visit> _provisionalVisit(AppDatabase database) async {
  await SiteDao(database).save(_site());
  final visit = await VisitDao(database).startVisit(siteId: 'site-1');
  return VisitDao(database).endVisit(visit);
}

void main() {
  group('VisitsScreen with a submitted Visit', () {
    testWidgets(
      'shows the submitted label and icon, not the in-progress ones',
      (tester) async {
        final database = _openDatabase();
        final submitted = await _submittedVisit(database);

        await tester.pumpWidget(
          _app(
            database,
            const VisitsScreen(
              projectId: 'project-1',
              surveyPeriodId: 'survey-period-1',
              protocolVersionId: 'protocol-version-1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(Key('visit_${submitted.id}')), findsOneWidget);
        expect(find.text('Submitted'), findsOneWidget);
        expect(find.text('In progress'), findsNothing);
        expect(
          find.byIcon(Icons.assignment_turned_in_outlined),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.timelapse_outlined), findsNothing);
      },
    );

    testWidgets('offers no End Visit action', (tester) async {
      final database = _openDatabase();
      final submitted = await _submittedVisit(database);

      await tester.pumpWidget(
        _app(
          database,
          const VisitsScreen(
            projectId: 'project-1',
            surveyPeriodId: 'survey-period-1',
            protocolVersionId: 'protocol-version-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('end_visit_${submitted.id}')), findsNothing);
    });
  });

  group('CaptureScreen with a submitted Visit', () {
    testWidgets('shows the submitted state label', (tester) async {
      final database = _openDatabase();
      final submitted = await _submittedVisit(database);

      await tester.pumpWidget(_app(database, CaptureScreen(visit: submitted)));
      await tester.pumpAndSettle();

      expect(find.text('State: Submitted'), findsOneWidget);
      expect(find.text('State: In progress'), findsNothing);
    });
  });

  testWidgets(
    'starting and ending a Visit from a Project with no pinned reference or '
    'Protocol version is not blocked (UX-032)',
    (tester) async {
      final database = _openDatabase();
      await SiteDao(database).save(_site());

      await tester.pumpWidget(
        _app(database, const VisitsScreen(projectId: 'project-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('start_visit_site-1')));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsOneWidget);
      final started = await VisitDao(database).all();
      expect(started, hasLength(1));
      expect(started.single.state, VisitState.inProgress);
      expect(started.single.protocolVersionId, isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('end_visit_${started.single.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('end_visit_confirm')));
      await tester.pumpAndSettle();

      final ended = await VisitDao(database).all();
      expect(ended.single.state, VisitState.ended);
      expect(ended.single.effort.endedAt, isNotNull);
    },
  );

  group('analysis-readiness (UX-035)', () {
    Visit provisionalVisit() => Visit(
      id: 'visit-1',
      siteId: 'site-1',
      state: VisitState.ended,
      effort: SamplingEffort(startedAt: DateTime.utc(2026, 1, 1)),
    );

    test('a Visit missing its Protocol version, Survey period, pinned '
        'reference and a resolved taxon is not analysis-ready and names each '
        'unmet requirement', () {
      final readiness = deriveVisitReadiness(
        visit: provisionalVisit(),
        detections: const <Detection>[
          Detection(
            visitId: 'visit-1',
            taxonRef: 'Turdus merula',
            detected: true,
            method: 'visual',
          ),
        ],
        targets: const <TargetTaxon>[],
        hasPinnedReference: false,
      );

      expect(readiness.isAnalysisReady, isFalse);
      expect(
        readiness.unmet,
        containsAll(<ReadinessRequirement>[
          ReadinessRequirement.protocolVersion,
          ReadinessRequirement.surveyPeriod,
          ReadinessRequirement.pinnedReference,
          ReadinessRequirement.unresolvedTaxa,
        ]),
      );
      expect(readiness.provisionalTaxonCount, 1);
    });

    test('a Visit with a Protocol version whose targets are unrecorded names '
        'the unrecorded targets', () {
      final readiness = deriveVisitReadiness(
        visit: Visit(
          id: 'visit-1',
          siteId: 'site-1',
          surveyPeriodId: 'survey-period-1',
          protocolVersionId: 'protocol-version-1',
          state: VisitState.ended,
          effort: SamplingEffort(startedAt: DateTime.utc(2026, 1, 1)),
        ),
        detections: const <Detection>[
          Detection(
            visitId: 'visit-1',
            taxonRef: 'Aves|Turdus|merula',
            detected: true,
            method: 'visual',
          ),
        ],
        targets: const <TargetTaxon>[
          TargetTaxon(taxonRef: 'Aves|Turdus|merula'),
          TargetTaxon(taxonRef: 'Aves|Parus|major'),
        ],
        hasPinnedReference: true,
      );

      expect(readiness.unmet, <ReadinessRequirement>[
        ReadinessRequirement.unrecordedTargets,
      ]);
      expect(readiness.unrecordedTargetCount, 1);
    });

    testWidgets('a provisional Visit carries the dashed outline marker '
        '(DESIGN.md § Component conventions, UX-033)', (tester) async {
      tester.view.physicalSize = const Size(200, 80);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: ProvisionalVisitMarker())),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('provisional_visit_marker')),
        matchesGoldenFile('goldens/provisional_visit_light.png'),
      );
    });

    testWidgets(
      'the needs-attention surface names each unmet requirement with an action',
      (tester) async {
        const readiness = VisitReadiness(
          unmet: <ReadinessRequirement>[
            ReadinessRequirement.protocolVersion,
            ReadinessRequirement.surveyPeriod,
            ReadinessRequirement.pinnedReference,
            ReadinessRequirement.unrecordedTargets,
            ReadinessRequirement.unresolvedTaxa,
          ],
          unrecordedTargetCount: 3,
          provisionalTaxonCount: 2,
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: NeedsAttention(readiness: readiness, onAction: (_) {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final requirement in ReadinessRequirement.values) {
          expect(
            find.byKey(Key('needs_attention_${requirement.name}')),
            findsOneWidget,
            reason: 'the surface names ${requirement.name}',
          );
          expect(
            find.byKey(Key('needs_attention_action_${requirement.name}')),
            findsOneWidget,
            reason: '${requirement.name} carries an action',
          );
        }
      },
    );

    testWidgets(
      'each needs-attention action opens the Project surface that clears its '
      'requirement (UX-035)',
      (tester) async {
        final database = _openDatabase();
        await ProjectDao(database).save(
          const Project(
            id: 'project-1',
            name: 'Alpine Birds',
            validationEnabled: false,
            sensitiveTaxaObfuscation: true,
          ),
        );
        final ended = await _provisionalVisit(database);

        const destinations = <ReadinessRequirement, String>{
          ReadinessRequirement.protocolVersion: 'protocol-surface',
          ReadinessRequirement.surveyPeriod: 'survey-periods-surface',
          ReadinessRequirement.pinnedReference: 'settings-surface',
        };
        for (final entry in destinations.entries) {
          await tester.pumpWidget(_routedCapture(database, ended));
          await tester.pumpAndSettle();

          final action = find.byKey(
            Key('needs_attention_action_${entry.key.name}'),
          );
          expect(action, findsOneWidget);
          await tester.ensureVisible(action);
          await tester.tap(action);
          await tester.pumpAndSettle();

          expect(
            find.text(entry.value),
            findsOneWidget,
            reason: '${entry.key.name} opens ${entry.value}',
          );
        }
      },
    );

    testWidgets(
      'a not analysis-ready Visit shows the provisional marker and the '
      'needs-attention surface (UX-033, UX-035)',
      (tester) async {
        final database = _openDatabase();
        final provisional = await _provisionalVisit(database);

        await tester.pumpWidget(
          _app(database, CaptureScreen(visit: provisional)),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('provisional_visit_marker')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('needs_attention_pinnedReference')),
          findsOneWidget,
        );
      },
    );

    testWidgets('an analysis-ready Visit shows neither the provisional marker '
        'nor the needs-attention surface (UX-033, UX-035)', (tester) async {
      final database = _openDatabase();
      await SiteDao(database).save(_site());
      await ProjectDao(database).save(
        const Project(
          id: 'project-1',
          name: 'Alpine Birds',
          validationEnabled: false,
          sensitiveTaxaObfuscation: true,
          taxonomicReferenceId: 'it-flora',
          taxonomicReferenceVersion: '2024.1',
        ),
      );
      final ready = await VisitDao(database).endVisit(
        await VisitDao(database).startVisit(
          siteId: 'site-1',
          surveyPeriodId: 'survey-period-1',
          protocolVersionId: 'protocol-version-1',
        ),
      );

      await tester.pumpWidget(_app(database, CaptureScreen(visit: ready)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('provisional_visit_marker')), findsNothing);
      expect(find.byType(NeedsAttention), findsNothing);
    });
  });
}
