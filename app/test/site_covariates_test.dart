import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/field_site.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/sites/site_covariates.dart';
import 'package:ibis/features/sites/sites_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/site_dao.dart';

const LocationFix _fix = LocationFix(
  position: LatLng(45.0, 9.0),
  method: LocationFixMethod.phoneSensor,
  accuracyMeters: 5.0,
);

class _FakeLocationService implements LocationService {
  @override
  Future<LocationFix> currentLocation() async => _fix;
}

ProtocolDocument buildDocument({
  List<CovariateDefinition>? siteCovariates,
  List<CovariateDefinition>? visitCovariates,
}) => ProtocolDocument(
  protocolId: 'project-1-protocol',
  version: 1,
  taxonomicScope: const TaxonomicScope(taxa: ['Aves']),
  detectionMethods: const [DetectionMethod(id: 'visual', label: 'Visual')],
  requiredEffortFields: const [SamplingEffortField.start],
  siteCovariates: siteCovariates,
  visitCovariates: visitCovariates,
);

const _habitat = CovariateDefinition(
  name: 'habitat',
  type: CovariateDefinitionType.text,
  unit: 'class',
);
const _windSpeed = CovariateDefinition(
  name: 'windSpeed',
  type: CovariateDefinitionType.number,
  unit: 'm/s',
);

ProtocolDocument _habitatDocument() => buildDocument(
  siteCovariates: const [_habitat],
  visitCovariates: const [_windSpeed],
);

Future<void> pumpSitesScreen(
  WidgetTester tester,
  AppDatabase database,
  ProtocolDocument document,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SitesScreen(projectId: 'project-1', protocol: document),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('create_site_here')));
  await tester.pumpAndSettle();
}

Future<List<Map<String, Object?>>> storedCovariates(
  AppDatabase database,
) async {
  final rows = await database.select(database.sites).get();
  final raw = rows.single.covariates;
  if (raw == null) return const [];
  return (jsonDecode(raw) as List).cast<Map<String, Object?>>();
}

void main() {
  test('offers exactly the site-covariate fields of the protocol document', () {
    final document = buildDocument(
      siteCovariates: const [_habitat],
      visitCovariates: const [_windSpeed],
    );

    expect(siteCovariateFields(document).map((field) => field.name).toList(), [
      'habitat',
    ]);
    expect(siteCovariateFields(buildDocument()), isEmpty);
  });

  test('a site covariate value carries its provenance and one without a method is rejected', () {
    final covariate = buildSiteCovariate(
      field: _habitat,
      value: 'forest',
      method: CovariateMethod.visualEstimate,
    );

    expect(covariate, isNotNull);
    expect(covariate!.name, 'habitat');
    expect(covariate.value, 'forest');
    expect(covariate.unit, 'class');
    expect(covariate.provenance.method, CovariateMethod.visualEstimate);

    expect(
      buildSiteCovariate(field: _habitat, value: 'forest', method: null),
      isNull,
    );

    expect(
      SiteCovariate.fromJson(covariate.toJson()).toJson(),
      covariate.toJson(),
    );
    expect(
      () => CovariateProvenance.fromJson(const {'method': 'telepathy'}),
      throwsFormatException,
    );
  });

  test('a site persists its covariate values with their provenance', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final dao = SiteDao(database);
    final site = Site(
      id: 'site-1',
      projectId: 'project-1',
      geometry: const PointGeometry(LatLng(45.0, 9.0)),
      origin: SiteOrigin.planned,
      createdAt: DateTime.utc(2026, 1, 1),
      covariates: const [
        SiteCovariate(
          name: 'habitat',
          value: 'forest',
          unit: 'class',
          provenance: CovariateProvenance(
            method: CovariateMethod.fieldInstrument,
          ),
        ),
      ],
    );

    await dao.save(site);

    final loaded = await dao.findById('site-1');
    expect(loaded, isNotNull);
    expect(loaded!.covariates, hasLength(1));
    expect(loaded.covariates.single.name, 'habitat');
    expect(loaded.covariates.single.value, 'forest');
    expect(loaded.covariates.single.unit, 'class');
    expect(
      loaded.covariates.single.provenance.method,
      CovariateMethod.fieldInstrument,
    );
  });

  testWidgets(
    'records a site covariate value with its provenance on the site screen',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await pumpSitesScreen(tester, database, _habitatDocument());

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('covariate_value_habitat')), findsOneWidget);
      expect(find.byKey(const Key('covariate_value_windSpeed')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('covariate_value_habitat')),
        'forest',
      );
      await tester.tap(find.byKey(const Key('covariate_method_habitat')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visual estimate').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('covariates_save')));
      await tester.pumpAndSettle();

      final covariates = await storedCovariates(database);
      expect(covariates, hasLength(1));
      expect(covariates.single['name'], 'habitat');
      expect(covariates.single['value'], 'forest');
      expect(covariates.single['unit'], 'class');
      expect(
        (covariates.single['provenance']! as Map)['method'],
        'visualEstimate',
      );
    },
  );

  testWidgets('rejects a covariate value entered without a method', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await pumpSitesScreen(tester, database, _habitatDocument());

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('covariate_value_habitat')),
      'forest',
    );
    await tester.tap(find.byKey(const Key('covariates_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('covariates_error')), findsOneWidget);
    expect(await storedCovariates(database), isEmpty);
  });

  test(
    'migrates a version 2 client schema to version 10 forward-only',
    () async {
      final database = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
CREATE TABLE sites (
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  geometry TEXT NOT NULL,
  origin TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  location_provenance TEXT,
  PRIMARY KEY (id)
);
''');
            raw.execute(
              "INSERT INTO sites (id, project_id, geometry, origin, created_at, location_provenance) "
              "VALUES ('legacy', 'project-1', "
              "'{\"type\":\"Point\",\"coordinates\":[9.0,45.0]}', 'planned', 1767225600, NULL);",
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
      );
      addTearDown(database.close);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data['user_version'], 19);

      final legacy = await SiteDao(database).findById('legacy');
      expect(legacy, isNotNull);
      expect(legacy!.covariates, isEmpty);

      final columns = await database
          .customSelect('PRAGMA table_info(sites)')
          .get();
      expect(columns.map((row) => row.data['name']), contains('covariates'));
    },
  );
}
