import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/field_site.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/sites/sites_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/site_dao.dart';

const LocationFix _fix = LocationFix(
  position: LatLng(45.0, 9.0),
  method: LocationFixMethod.phoneSensor,
  accuracyMeters: 5.0,
);

class FakeLocationService implements LocationService {
  FakeLocationService(this.fix);

  final LocationFix fix;
  Object? error;

  @override
  Future<LocationFix> currentLocation() async {
    final failure = error;
    if (failure != null) throw failure;
    return fix;
  }
}

void main() {
  test('without connectivity, creating a site from the current location saves it with origin field', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final dao = SiteDao(database);

    final site = await createFieldSite(
      locationService: FakeLocationService(_fix),
      dao: dao,
      projectId: 'project-1',
    );

    final loaded = await dao.findById(site.id);
    expect(loaded, isNotNull);
    expect(loaded!.origin, SiteOrigin.field);
    expect(loaded.projectId, 'project-1');
    expect(loaded.geometry, isA<PointGeometry>());
    expect((loaded.geometry as PointGeometry).point, const LatLng(45.0, 9.0));
  });

  test(
    'a field site records the location fix provenance method and accuracy',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final dao = SiteDao(database);

      final site = await createFieldSite(
        locationService: FakeLocationService(
          const LocationFix(
            position: LatLng(45.1, 9.2),
            method: LocationFixMethod.phoneSensor,
            accuracyMeters: 7.5,
          ),
        ),
        dao: dao,
        projectId: 'project-1',
      );

      final loaded = await dao.findById(site.id);
      expect(loaded!.locationProvenance, isNotNull);
      expect(loaded.locationProvenance!.method, LocationFixMethod.phoneSensor);
      expect(loaded.locationProvenance!.accuracyMeters, 7.5);
    },
  );

  test('site location provenance serialises and rejects malformed input', () {
    const provenance = SiteLocationProvenance(
      method: LocationFixMethod.phoneSensor,
      accuracyMeters: 3.5,
    );
    expect(
      SiteLocationProvenance.fromJson(provenance.toJson()).toJson(),
      provenance.toJson(),
    );
    expect(
      () => SiteLocationProvenance.fromJson(const {'method': 'lidar'}),
      throwsFormatException,
    );
    expect(
      () => SiteLocationProvenance.fromJson(const {
        'method': 'lidar',
        'accuracyMeters': 1.0,
      }),
      throwsFormatException,
    );
  });

  test(
    'a field site is readable from the local store after the app restarts',
    () async {
      final directory = Directory.systemTemp.createTempSync('ibis_field_site');
      addTearDown(() => directory.deleteSync(recursive: true));
      final path = '${directory.path}/ibis.sqlite';

      var database = AppDatabase.open(path);
      final site = await createFieldSite(
        locationService: FakeLocationService(_fix),
        dao: SiteDao(database),
        projectId: 'project-1',
      );
      await database.close();

      database = AppDatabase.open(path);
      final loaded = await SiteDao(database).findById(site.id);
      await database.close();

      expect(loaded, isNotNull);
      expect(loaded!.origin, SiteOrigin.field);
      expect(loaded.locationProvenance, isNotNull);
      expect(loaded.locationProvenance!.method, LocationFixMethod.phoneSensor);
      expect(loaded.locationProvenance!.accuracyMeters, 5.0);
    },
  );

  testWidgets(
    'the Sites screen creates a field site from the current location',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            locationServiceProvider.overrideWithValue(
              FakeLocationService(_fix),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SitesScreen(projectId: 'project-1'),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('create_site_here')));
      await tester.pumpAndSettle();

      final rows = await database.select(database.sites).get();
      expect(rows, hasLength(1));
      expect(rows.single.origin, SiteOrigin.field);
    },
  );

  testWidgets(
    'the Sites screen reports a location failure without saving a site',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            locationServiceProvider.overrideWithValue(
              FakeLocationService(_fix)..error = Exception('no location'),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SitesScreen(projectId: 'project-1'),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('create_site_here')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(await database.select(database.sites).get(), isEmpty);
    },
  );

  test('migrates a version 1 client schema to version 9 forward-only', () async {
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
  PRIMARY KEY (id)
);
''');
          raw.execute(
            "INSERT INTO sites (id, project_id, geometry, origin, created_at) "
            "VALUES ('legacy', 'project-1', "
            "'{\"type\":\"Point\",\"coordinates\":[9.0,45.0]}', 'planned', 1767225600);",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(database.close);

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], 9);

    final legacy = await SiteDao(database).findById('legacy');
    expect(legacy, isNotNull);
    expect(legacy!.origin, SiteOrigin.planned);
    expect(legacy.locationProvenance, isNull);
    expect(legacy.covariates, isEmpty);

    final columns = await database
        .customSelect('PRAGMA table_info(sites)')
        .get();
    expect(
      columns.map((row) => row.data['name']),
      contains('location_provenance'),
    );
    expect(columns.map((row) => row.data['name']), contains('covariates'));
  });
}
