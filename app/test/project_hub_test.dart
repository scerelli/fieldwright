import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/sites/field_site.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/sites/sites_screen.dart';
import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/projects/members_client.dart';
import 'package:ibis/projects/projects_client.dart';
import 'package:ibis/projects/survey_periods_client.dart';
import 'package:ibis/protocol_versions/protocol_versions_client.dart';
import 'package:ibis/router/app_router.dart';
import 'package:ibis/shell/app_shell.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/project_dao.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';
import 'package:ibis/features/visits/visit.dart';

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._handle);

  final Future<ResponseBody> Function(RequestOptions options) _handle;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _handle(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

FakeHttpAdapter emptyAdapter() => FakeHttpAdapter((options) async {
  if (options.path == '/projects/p1/members' && options.method == 'GET') {
    return jsonResponse(const <dynamic>[]);
  }
  if (options.path == '/survey-periods' && options.method == 'GET') {
    return jsonResponse(const <dynamic>[]);
  }
  if (options.path == '/projects/p1/protocol-versions' &&
      options.method == 'GET') {
    return jsonResponse(const <dynamic>[]);
  }
  return jsonResponse(<String, dynamic>{
    'message': 'not found',
  }, statusCode: 404);
});

Dio fakeDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = emptyAdapter();
  return dio;
}

const Project projectOne = Project(
  id: 'p1',
  name: 'Alpine Birds',
  validationEnabled: false,
  sensitiveTaxaObfuscation: true,
);

const Project projectTwo = Project(
  id: 'p2',
  name: 'Wetland Survey',
  validationEnabled: false,
  sensitiveTaxaObfuscation: true,
);

Site siteOf(String id, String projectId, double lat) => Site(
  id: id,
  projectId: projectId,
  geometry: PointGeometry(LatLng(lat, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

AppDatabase openDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

class FakeLocationService implements LocationService {
  @override
  Future<LocationFix> currentLocation() async => const LocationFix(
    position: LatLng(45.0, 9.0),
    method: LocationFixMethod.phoneSensor,
    accuracyMeters: 5.0,
  );
}

class Seeded {
  Seeded(this.database, this.visitOfP1, this.visitOfP2);

  final AppDatabase database;
  final Visit visitOfP1;
  final Visit visitOfP2;
}

Future<Seeded> seed(AppDatabase database) async {
  final projects = ProjectDao(database);
  await projects.save(projectOne);
  await projects.save(projectTwo);

  final sites = SiteDao(database);
  await sites.save(siteOf('s1', 'p1', 45.0));
  await sites.save(siteOf('s2', 'p2', 46.0));

  final visits = VisitDao(database);
  final visitOfP1 = await visits.startVisit(
    siteId: 's1',
    surveyPeriodId: 'sp1',
    protocolVersionId: 'pv1',
  );
  final visitOfP2 = await visits.startVisit(
    siteId: 's2',
    surveyPeriodId: 'sp2',
    protocolVersionId: 'pv2',
  );
  return Seeded(database, visitOfP1, visitOfP2);
}

ProviderContainer containerWith(
  AppDatabase database, {
  LocationService? locationService,
}) {
  final auth = AuthClient(baseUrl: 'http://test.local', dio: fakeDio());
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      if (locationService != null)
        locationServiceProvider.overrideWithValue(locationService),
      protocolVersionsClientProvider.overrideWithValue(
        ProtocolVersionsClient(
          baseUrl: 'http://test.local',
          auth: auth,
          dio: fakeDio(),
        ),
      ),
      membersClientProvider.overrideWithValue(
        MembersClient(baseUrl: 'http://test.local', auth: auth, dio: fakeDio()),
      ),
      surveyPeriodsClientProvider.overrideWithValue(
        SurveyPeriodsClient(
          baseUrl: 'http://test.local',
          auth: auth,
          dio: fakeDio(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

String currentPath(WidgetTester tester) =>
    GoRouterState.of(tester.element(find.byType(AppShell))).uri.path;

Future<void> pumpHub(
  WidgetTester tester,
  ProviderContainer container, {
  required Project project,
  bool withExtra = true,
}) async {
  final router = container.read(goRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  router.go('/projects/${project.id}', extra: withExtra ? project : null);
  await tester.pumpAndSettle();
}

const ProtocolDocument _covariateProtocol = ProtocolDocument(
  protocolId: 'p1-protocol',
  version: 1,
  taxonomicScope: TaxonomicScope(taxa: <String>['Aves']),
  detectionMethods: <DetectionMethod>[
    DetectionMethod(id: 'visual', label: 'Visual'),
  ],
  requiredEffortFields: <SamplingEffortField>[SamplingEffortField.start],
  siteCovariates: <CovariateDefinition>[
    CovariateDefinition(
      name: 'habitat',
      type: CovariateDefinitionType.text,
      unit: 'class',
    ),
  ],
);

void main() {
  testWidgets('the Sites tab lists only the open Project\'s Sites '
      '(INV-012, UX-019)', (tester) async {
    final seeded = await seed(openDatabase());
    await pumpHub(tester, containerWith(seeded.database), project: projectOne);

    expect(find.byKey(const Key('site_s1')), findsOneWidget);
    expect(find.byKey(const Key('site_s2')), findsNothing);
  });

  testWidgets('the Visits tab lists only the open Project\'s Visits and Sites '
      '(UX-019)', (tester) async {
    final seeded = await seed(openDatabase());
    await pumpHub(tester, containerWith(seeded.database), project: projectOne);

    await tester.tap(find.byKey(const Key('hub_visits_tab')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('visit_${seeded.visitOfP1.id}')), findsOneWidget);
    expect(find.byKey(Key('visit_${seeded.visitOfP2.id}')), findsNothing);
    expect(find.byKey(const Key('start_visit_s1')), findsOneWidget);
    expect(find.byKey(const Key('start_visit_s2')), findsNothing);
  });

  testWidgets('the open Project\'s name stays visible in the hub, resolved '
      'from the store on a deep link (UX-020)', (tester) async {
    final seeded = await seed(openDatabase());
    await pumpHub(
      tester,
      containerWith(seeded.database),
      project: projectOne,
      withExtra: false,
    );

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Alpine Birds'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a Visit starts from a Site row in the hub '
      '(UX-009, UX-032)', (tester) async {
    final seeded = await seed(openDatabase());
    await pumpHub(tester, containerWith(seeded.database), project: projectOne);

    await tester.tap(find.byKey(const Key('hub_visits_tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_visit_s1')));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsOneWidget);
    final visits = await VisitDao(seeded.database).all();
    expect(visits.where((visit) => visit.siteId == 's1'), hasLength(2));
    expect(visits.where((visit) => visit.siteId == 's2'), hasLength(1));
  });

  testWidgets('the hub overflow reaches the Project config surfaces '
      '(UX-019)', (tester) async {
    final seeded = await seed(openDatabase());
    await pumpHub(tester, containerWith(seeded.database), project: projectOne);

    Future<void> openOverflow() async {
      await tester.tap(find.byKey(const Key('project_config_overflow')));
      await tester.pumpAndSettle();
    }

    await openOverflow();
    expect(find.byKey(const Key('open_protocol_version')), findsOneWidget);
    expect(find.byKey(const Key('open_members')), findsOneWidget);
    expect(find.byKey(const Key('open_survey_periods')), findsOneWidget);

    await tester.tap(find.byKey(const Key('open_protocol_version')));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/projects/p1/protocol');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openOverflow();
    await tester.tap(find.byKey(const Key('open_members')));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/projects/p1/members');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openOverflow();
    await tester.tap(find.byKey(const Key('open_survey_periods')));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/projects/p1/survey-periods');
  });

  testWidgets(
    'saving a Site covariate keeps the Site\'s location provenance and its '
    'previously stored covariates (F1, INV-012)',
    (tester) async {
      final database = openDatabase();
      final dao = SiteDao(database);
      await dao.save(
        Site(
          id: 's1',
          projectId: 'p1',
          geometry: const PointGeometry(LatLng(45.0, 9.0)),
          origin: SiteOrigin.field,
          createdAt: DateTime.utc(2026, 1, 1),
          locationProvenance: const SiteLocationProvenance(
            method: LocationFixMethod.phoneSensor,
            accuracyMeters: 5.0,
          ),
          covariates: const <SiteCovariate>[
            SiteCovariate(
              name: 'habitat',
              value: 'forest',
              unit: 'class',
              provenance: CovariateProvenance(
                method: CovariateMethod.visualEstimate,
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SitesScreen(projectId: 'p1', protocol: _covariateProtocol),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('site_s1')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('covariate_value_habitat')),
        'wetland',
      );
      await tester.tap(find.byKey(const Key('covariate_method_habitat')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visual estimate').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('covariates_save')));
      await tester.pumpAndSettle();

      final stored = await dao.findById('s1');
      expect(stored, isNotNull);
      expect(stored!.locationProvenance, isNotNull);
      expect(stored.locationProvenance!.accuracyMeters, 5.0);
      expect(stored.covariates.single.value, 'wetland');
    },
  );

  testWidgets(
    'a Site added on the Sites tab appears on the Visits tab without a restart '
    '(UX-009, UX-019)',
    (tester) async {
      final seeded = await seed(openDatabase());
      await pumpHub(
        tester,
        containerWith(seeded.database, locationService: FakeLocationService()),
        project: projectOne,
      );

      // Open the Visits tab first so it caches the Project's Site list.
      await tester.tap(find.byKey(const Key('hub_visits_tab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('start_visit_s1')), findsOneWidget);

      // Add a field Site from the Sites tab.
      await tester.tap(find.byKey(const Key('hub_sites_tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create_site_here')));
      await tester.pumpAndSettle();

      final sites = await SiteDao(seeded.database).findByProject('p1');
      expect(sites, hasLength(2));
      final added = sites.firstWhere((site) => site.id != 's1');

      // The cached Visits tab must show the new Site without a restart.
      await tester.tap(find.byKey(const Key('hub_visits_tab')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('start_visit_${added.id}')), findsOneWidget);
    },
  );
}
