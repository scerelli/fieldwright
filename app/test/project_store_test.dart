import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/outbox/config_sync_client.dart';
import 'package:ibis/projects/projects_client.dart';
import 'package:ibis/projects/survey_periods_client.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/protocol_versions/protocol_versions_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/config_dao.dart';
import 'package:ibis/store/project_dao.dart';

const Project _project = Project(
  id: 'p1',
  name: 'River survey',
  validationEnabled: true,
  sensitiveTaxaObfuscation: false,
  taxonomicReferenceId: 'italy-vascular-flora',
  taxonomicReferenceVersion: '2024.1',
);

const ProtocolDocument _document = ProtocolDocument(
  protocolId: 'alpine-birds-2026',
  version: 1,
  taxonomicScope: TaxonomicScope(taxa: ['Aves']),
  detectionMethods: [DetectionMethod(id: 'visual', label: 'Visual detection')],
  requiredEffortFields: [SamplingEffortField.start],
  targetList: [
    TargetTaxon(taxonRef: 'Aves|Turdus|merula', label: 'Common blackbird'),
  ],
);

const ProtocolVersion _protocolVersion = ProtocolVersion(
  id: 'pv1',
  projectId: 'p1',
  document: _document,
);

const SurveyPeriod _surveyPeriod = SurveyPeriod(
  id: 'sp1',
  projectId: 'p1',
  name: 'Spring 2026',
  startDate: '2026-03-01',
  endDate: '2026-05-31',
);

Site _site({String id = 's1', String projectId = 'p1'}) => Site(
  id: id,
  projectId: projectId,
  geometry: const PointGeometry(LatLng(45.46, 9.19)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 9, 30),
);

Directory _tempDirectory() {
  final directory = Directory.systemTemp.createTempSync('ibis_project_store');
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}

void main() {
  test(
    'C1: the store persists a Project with its Protocol version, Survey '
    'periods and Sites, and reads them back after the database is reopened',
    () async {
      final path = '${_tempDirectory().path}/ibis.sqlite';

      var database = AppDatabase.open(path);
      await ProjectDao(database).save(_project);
      await ProjectDao(database).saveProtocolVersion(_protocolVersion);
      await ProjectDao(database).saveSurveyPeriod(_surveyPeriod);
      await ProjectDao(database).saveSite(_site());
      await database.close();

      database = AppDatabase.open(path);
      addTearDown(database.close);
      final dao = ProjectDao(database);

      final project = await dao.findById('p1');
      expect(project, isNotNull);
      expect(project!.name, 'River survey');
      expect(project.validationEnabled, isTrue);
      expect(project.sensitiveTaxaObfuscation, isFalse);
      expect(project.taxonomicReferenceId, 'italy-vascular-flora');
      expect(project.taxonomicReferenceVersion, '2024.1');

      final version = await dao.latestProtocolVersion('p1');
      expect(version, isNotNull);
      expect(version!.id, 'pv1');
      expect(
        version.document.targetList?.single.taxonRef,
        'Aves|Turdus|merula',
      );

      final periods = await dao.surveyPeriods('p1');
      expect(periods.single.id, 'sp1');
      expect(periods.single.name, 'Spring 2026');
      expect(periods.single.startDate, '2026-03-01');
      expect(periods.single.endDate, '2026-05-31');

      final sites = await dao.sites('p1');
      expect(sites.single.id, 's1');
      expect(sites.single.origin, SiteOrigin.planned);
      expect(sites.single.geometry, isA<PointGeometry>());
    },
  );

  test('C2: a locally-created Project keeps the identity assigned at creation '
      'across reads (INV-015)', () async {
    final path = '${_tempDirectory().path}/ibis.sqlite';

    var database = AppDatabase.open(path);
    final dao = ProjectDao(database);
    await dao.save(
      const Project(
        id: 'local-uuidv7',
        name: 'Offline survey',
        validationEnabled: false,
        sensitiveTaxaObfuscation: true,
        taxonomicReferenceId: 'it-flora',
        taxonomicReferenceVersion: '2024.1',
      ),
    );
    expect((await dao.findById('local-uuidv7'))!.id, 'local-uuidv7');
    await database.close();

    database = AppDatabase.open(path);
    addTearDown(database.close);
    final reopened = ProjectDao(database);
    expect((await reopened.findById('local-uuidv7'))!.id, 'local-uuidv7');

    await reopened.save(
      const Project(
        id: 'local-uuidv7',
        name: 'Renamed offline survey',
        validationEnabled: true,
        sensitiveTaxaObfuscation: false,
        taxonomicReferenceId: 'it-flora',
        taxonomicReferenceVersion: '2025.2',
      ),
    );
    final renamed = await reopened.findById('local-uuidv7');
    expect(renamed!.id, 'local-uuidv7');
    expect(renamed.name, 'Renamed offline survey');
  });

  test('C3: the config pull and local creation write the same aggregate tables '
      'and no separate pull-cache representation remains', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final projects = ProjectDao(database);

    await projects.save(_project);

    await ConfigDao(database).apply(
      ConfigPull(
        versionToken: 'token-1',
        project: const Project(
          id: 'p2',
          name: 'Joined survey',
          validationEnabled: false,
          sensitiveTaxaObfuscation: true,
          taxonomicReferenceId: 'it-flora',
          taxonomicReferenceVersion: '2025.2',
        ),
        protocolVersion: const ProtocolVersion(
          id: 'pv2',
          projectId: 'p2',
          document: _document,
        ),
        surveyPeriods: const [
          SurveyPeriod(
            id: 'sp2',
            projectId: 'p2',
            name: 'Autumn 2026',
            startDate: '2026-09-01',
            endDate: '2026-11-30',
          ),
        ],
        sites: [
          ConfigSite(
            id: 's2',
            projectId: 'p2',
            name: 'Site B',
            geom: '{"type":"Point","coordinates":[9.2,45.5]}',
            createdAt: DateTime.utc(2026, 9, 30),
          ),
        ],
      ),
      projectId: 'p2',
    );

    // The locally-created and the pulled Project are both read through the
    // same aggregate DAO and live in the same `projects` table.
    expect((await projects.findById('p1'))!.name, 'River survey');
    expect((await projects.findById('p2'))!.name, 'Joined survey');
    expect((await projects.sites('p2')).single.id, 's2');

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN "
          "('projects', 'protocol_versions', 'survey_periods', 'sites', "
          "'project_configs', 'config_sites')",
        )
        .get();
    final names = tables.map((row) => row.data['name']).toSet();
    expect(
      names,
      containsAll(<String>[
        'projects',
        'protocol_versions',
        'survey_periods',
        'sites',
      ]),
    );
    expect(names, isNot(contains('project_configs')));
    expect(names, isNot(contains('config_sites')));

    final rows = await database
        .customSelect('SELECT id FROM projects ORDER BY id')
        .get();
    expect(rows.map((row) => row.data['id']), ['p1', 'p2']);
  });

  test(
    'C4: saving a locally-created Site preserves the name a config pull set',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final projects = ProjectDao(database);

      await projects.saveSite(_site(), name: 'Site A');
      await projects.saveSite(_site());

      expect((await ConfigDao(database).sites('p1')).single.name, 'Site A');
    },
  );

  test('C5: a config pull preserves a locally-created field Site\'s origin, '
      'provenance and covariates', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final projects = ProjectDao(database);

    await projects.saveSite(
      Site(
        id: 's1',
        projectId: 'p1',
        geometry: const PointGeometry(LatLng(45.46, 9.19)),
        origin: SiteOrigin.field,
        createdAt: DateTime.utc(2026, 9, 30),
        locationProvenance: const SiteLocationProvenance(
          method: LocationFixMethod.phoneSensor,
          accuracyMeters: 4.2,
        ),
        covariates: const [
          SiteCovariate(
            name: 'canopy_cover',
            value: '40',
            provenance: CovariateProvenance(
              method: CovariateMethod.visualEstimate,
            ),
          ),
        ],
      ),
    );

    await ConfigDao(database).apply(
      ConfigPull(
        versionToken: 'token-1',
        sites: [
          ConfigSite(
            id: 's1',
            projectId: 'p1',
            name: 'Linked site',
            geom: '{"type":"Point","coordinates":[9.2,45.5]}',
            createdAt: DateTime.utc(2026, 10, 1),
          ),
        ],
      ),
      projectId: 'p1',
    );

    final stored = (await projects.sites('p1')).single;
    expect(stored.origin, SiteOrigin.field);
    expect(stored.locationProvenance!.accuracyMeters, 4.2);
    expect(stored.covariates.single.name, 'canopy_cover');
    expect(stored.geometry, isA<PointGeometry>());

    final transport = (await ConfigDao(database).sites('p1')).single;
    expect(transport.name, 'Linked site');
  });

  test('migration: a version 15 store migrates forward to 16, moving the pull '
      'cache into the Project aggregate', () async {
    final migrated = AppDatabase(
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
  covariates TEXT,
  PRIMARY KEY (id)
);
''');
          raw.execute('''
CREATE TABLE project_configs (
  project_id TEXT NOT NULL,
  name TEXT NOT NULL,
  validation_enabled INTEGER NOT NULL,
  sensitive_taxa_obfuscation INTEGER NOT NULL,
  taxonomic_reference_id TEXT NOT NULL,
  taxonomic_reference_version TEXT NOT NULL,
  PRIMARY KEY (project_id)
);
''');
          raw.execute('''
CREATE TABLE config_sites (
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  name TEXT,
  geom TEXT,
  created_at INTEGER,
  PRIMARY KEY (id)
);
''');
          raw.execute(
            "INSERT INTO project_configs VALUES "
            "('p1', 'River survey', 1, 0, 'it-flora', '2024.1')",
          );
          raw.execute(
            "INSERT INTO config_sites VALUES "
            "('s1', 'p1', 'Site A', "
            "'{\"type\":\"Point\",\"coordinates\":[9.19,45.46]}', 1700000000)",
          );
          raw.execute('PRAGMA user_version = 15');
        },
      ),
    );
    addTearDown(migrated.close);

    final version = await migrated
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], 16);

    final project = await ProjectDao(migrated).findById('p1');
    expect(project, isNotNull);
    expect(project!.name, 'River survey');

    final sites = await ProjectDao(migrated).sites('p1');
    expect(sites.single.id, 's1');
    expect(sites.single.origin, SiteOrigin.planned);

    final dropped = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN "
          "('project_configs', 'config_sites')",
        )
        .get();
    expect(dropped, isEmpty);
  });

  test('migration: a version 15 store with geometry-less and undated '
      'config_sites rows migrates to 16 without aborting', () async {
    final migrated = AppDatabase(
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
  covariates TEXT,
  PRIMARY KEY (id)
);
''');
          raw.execute('''
CREATE TABLE project_configs (
  project_id TEXT NOT NULL,
  name TEXT NOT NULL,
  validation_enabled INTEGER NOT NULL,
  sensitive_taxa_obfuscation INTEGER NOT NULL,
  taxonomic_reference_id TEXT NOT NULL,
  taxonomic_reference_version TEXT NOT NULL,
  PRIMARY KEY (project_id)
);
''');
          raw.execute('''
CREATE TABLE config_sites (
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  name TEXT,
  geom TEXT,
  created_at INTEGER,
  PRIMARY KEY (id)
);
''');
          raw.execute(
            "INSERT INTO project_configs VALUES "
            "('p1', 'River survey', 1, 0, 'it-flora', '2024.1')",
          );
          raw.execute(
            "INSERT INTO config_sites VALUES "
            "('s-geomless', 'p1', 'Unplaced', NULL, NULL)",
          );
          raw.execute(
            "INSERT INTO config_sites VALUES "
            "('s-undated', 'p1', 'Undated', "
            "'{\"type\":\"Point\",\"coordinates\":[9.2,45.5]}', NULL)",
          );
          raw.execute(
            "INSERT INTO config_sites VALUES "
            "('s-valid', 'p1', 'Site A', "
            "'{\"type\":\"Point\",\"coordinates\":[9.19,45.46]}', 1700000000)",
          );
          raw.execute('PRAGMA user_version = 15');
        },
      ),
    );
    addTearDown(migrated.close);

    final version = await migrated
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], 16);

    // The geometry-less row cannot become a domain Site and is dropped; the
    // undated row is kept with a safe created_at; the valid row survives.
    final sites = await ProjectDao(migrated).sites('p1');
    expect(
      sites.map((site) => site.id),
      unorderedEquals(<String>['s-undated', 's-valid']),
    );
  });

  test('migration: a version 15 config_sites row colliding with a stored Site '
      'keeps the Site\'s client-owned fields', () async {
    final migrated = AppDatabase(
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
  covariates TEXT,
  PRIMARY KEY (id)
);
''');
          raw.execute('''
CREATE TABLE config_sites (
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  name TEXT,
  geom TEXT,
  created_at INTEGER,
  PRIMARY KEY (id)
);
''');
          raw.execute(
            "INSERT INTO sites VALUES "
            "('s1', 'p1', "
            "'{\"type\":\"Point\",\"coordinates\":[9.19,45.46]}', "
            "'field', 1700000000, "
            "'{\"method\":\"phoneSensor\",\"accuracyMeters\":4.2}', "
            "'[{\"name\":\"canopy_cover\",\"value\":\"40\","
            "\"unit\":null,\"provenance\":{\"method\":\"visualEstimate\"}}]')",
          );
          raw.execute(
            "INSERT INTO config_sites VALUES "
            "('s1', 'p1', 'Linked site', "
            "'{\"type\":\"Point\",\"coordinates\":[9.2,45.5]}', 1700000100)",
          );
          raw.execute('PRAGMA user_version = 15');
        },
      ),
    );
    addTearDown(migrated.close);

    final sites = await ProjectDao(migrated).sites('p1');
    expect(sites.single.origin, SiteOrigin.field);
    expect(sites.single.locationProvenance!.accuracyMeters, 4.2);
    expect(sites.single.covariates.single.name, 'canopy_cover');

    final transport = (await ConfigDao(migrated).sites('p1')).single;
    expect(transport.name, 'Linked site');
  });
}
