import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/outbox/config_sync_client.dart';
import 'package:ibis/projects/projects_client.dart';
import 'package:ibis/projects/survey_periods_client.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/protocol_versions/protocol_versions_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/config_dao.dart';

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

final ConfigSite _configSite = ConfigSite(
  id: 's1',
  projectId: 'p1',
  name: 'Site A',
  geom: '{"type":"Point","coordinates":[9.19,45.46]}',
  createdAt: DateTime.utc(2026, 9, 30),
);

ConfigPull fullPull({String token = '1700000000000001'}) => ConfigPull(
  versionToken: token,
  project: _project,
  protocolVersion: _protocolVersion,
  surveyPeriods: const [_surveyPeriod],
  sites: [_configSite],
);

/// A pull the server returns when nothing changed: no Project, no Protocol
/// version and empty lists. Its token differs to make "unchanged" falsifiable.
ConfigPull noChangePull({String token = '1700000000000002'}) =>
    ConfigPull(versionToken: token);

/// A pulled response whose Protocol version document is missing the fields the
/// shared schema requires (`packages/protocol`, ADR-0009).
Map<String, dynamic> nonconformingBody() => <String, dynamic>{
  'versionToken': '1700000000000001',
  'project': <String, dynamic>{
    'id': 'p1',
    'name': 'River survey',
    'settings': <String, dynamic>{},
    'taxonomicReferenceId': 'italy-vascular-flora',
    'taxonomicReferenceVersion': '2024.1',
  },
  'protocolVersion': <String, dynamic>{
    'id': 'pv1',
    'projectId': 'p1',
    'document': <String, dynamic>{'protocolId': 'alpine-birds-2026'},
  },
  'surveyPeriods': <Map<String, dynamic>>[],
  'sites': <Map<String, dynamic>>[],
};

AppDatabase openDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

void main() {
  test('applying a pulled configuration caches the Project, Protocol version with its Target list, Survey periods and Sites', () async {
    final dao = ConfigDao(openDatabase());

    await dao.apply(fullPull(), projectId: 'p1');

    final project = await dao.project('p1');
    expect(project, isNotNull);
    expect(project!.name, 'River survey');
    expect(project.validationEnabled, isTrue);
    expect(project.sensitiveTaxaObfuscation, isFalse);
    expect(project.taxonomicReferenceId, 'italy-vascular-flora');
    expect(project.taxonomicReferenceVersion, '2024.1');

    final version = await dao.latestProtocolVersion('p1');
    expect(version, isNotNull);
    expect(version!.document.protocolId, 'alpine-birds-2026');
    expect(version.document.targetList?.single.taxonRef, 'Aves|Turdus|merula');

    final periods = await dao.surveyPeriods('p1');
    expect(periods.single.name, 'Spring 2026');
    expect(periods.single.startDate, '2026-03-01');
    expect(periods.single.endDate, '2026-05-31');

    final sites = await dao.sites('p1');
    expect(sites.single.id, 's1');
    expect(sites.single.name, 'Site A');
    expect(sites.single.geom, '{"type":"Point","coordinates":[9.19,45.46]}');
  });

  test('the persisted version token advances to an applied pull so the next pull sends it', () async {
    final dao = ConfigDao(openDatabase());

    await dao.apply(fullPull(token: 'token-1'), projectId: 'p1');
    expect(await dao.versionToken('p1'), 'token-1');

    await dao.apply(fullPull(token: 'token-2'), projectId: 'p1');
    expect(await dao.versionToken('p1'), 'token-2');
  });

  test('a Protocol version document that does not conform is rejected and nothing is cached', () async {
    final dao = ConfigDao(openDatabase());

    await expectLater(() async {
      final pull = ConfigPull.fromJson(nonconformingBody());
      await dao.apply(pull, projectId: 'p1');
    }, throwsA(isA<FormatException>()));

    expect(await dao.project('p1'), isNull);
    expect(await dao.latestProtocolVersion('p1'), isNull);
    expect(await dao.surveyPeriods('p1'), isEmpty);
    expect(await dao.sites('p1'), isEmpty);
    expect(await dao.versionToken('p1'), isNull);
  });

  test('a pull with no changes leaves the cached configuration and the persisted version token unchanged', () async {
    final dao = ConfigDao(openDatabase());

    await dao.apply(fullPull(token: 'token-1'), projectId: 'p1');

    await dao.apply(noChangePull(token: 'token-2'), projectId: 'p1');

    expect((await dao.project('p1'))!.name, 'River survey');
    expect((await dao.latestProtocolVersion('p1'))!.id, 'pv1');
    expect((await dao.surveyPeriods('p1')).single.id, 'sp1');
    expect((await dao.sites('p1')).single.id, 's1');
    expect(await dao.versionToken('p1'), 'token-1');
  });

  group('migration', () {
    test(
      'migrates a version 8 client schema to version 10 forward-only',
      () async {
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
CREATE TABLE visits (
  id TEXT NOT NULL,
  site_id TEXT NOT NULL,
  survey_period_id TEXT NOT NULL,
  protocol_version_id TEXT NOT NULL,
  state TEXT NOT NULL,
  effort_started_at INTEGER NOT NULL,
  effort_ended_at INTEGER,
  PRIMARY KEY (id)
);
''');
              raw.execute('''
CREATE TABLE detections (
  visit_id TEXT NOT NULL,
  taxon_ref TEXT NOT NULL,
  detected INTEGER NOT NULL,
  opportunistic INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (visit_id, taxon_ref)
);
''');
              raw.execute('''
CREATE TABLE evidences (
  id TEXT NOT NULL,
  visit_id TEXT NOT NULL,
  taxon_ref TEXT NOT NULL,
  kind TEXT NOT NULL,
  file_path TEXT NOT NULL,
  captured_at INTEGER NOT NULL,
  content_hash TEXT NOT NULL,
  PRIMARY KEY (id)
);
''');
              raw.execute('''
CREATE TABLE measurements (
  id TEXT NOT NULL,
  visit_id TEXT NOT NULL,
  name TEXT NOT NULL,
  value TEXT NOT NULL,
  unit TEXT,
  provenance TEXT NOT NULL,
  PRIMARY KEY (id)
);
''');
              raw.execute('PRAGMA user_version = 8');
            },
          ),
        );
        addTearDown(migrated.close);

        final version = await migrated
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 13);

        final tables = await migrated
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN "
              "('project_configs', 'protocol_versions', 'survey_periods', "
              "'config_sites', 'config_states')",
            )
            .get();
        expect(tables, hasLength(5));

        await ConfigDao(migrated).apply(fullPull(), projectId: 'p1');
        expect((await ConfigDao(migrated).project('p1'))!.name, 'River survey');
      },
    );

    test('round-trips the cached Protocol document through JSON', () async {
      final database = openDatabase();
      await ConfigDao(database).apply(fullPull(), projectId: 'p1');

      final stored = await database
          .customSelect(
            "SELECT document FROM protocol_versions WHERE id = 'pv1'",
          )
          .getSingle();
      final document = ProtocolDocument.fromJson(
        jsonDecode(stored.data['document']! as String) as Map<String, dynamic>,
      );
      expect(document.targetList?.single.taxonRef, 'Aves|Turdus|merula');
    });
  });
}
