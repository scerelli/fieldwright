import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/features/visits/determination.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/determination_dao.dart';
import 'package:ibis/store/visit_dao.dart';

AppDatabase openDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

Future<Visit> _startVisit(AppDatabase database) => VisitDao(database)
    .startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
    );

/// A fully-populated Determination — every field a non-default value — so a
/// dropped or reordered field is caught on reload.
Determination _determination({
  String id = 'determination-1',
  String taxon = 'Anthus trivialis',
  DeterminationQualifier? qualifier = DeterminationQualifier.cf,
  String? specimenCode = 'SP-1',
  String determiner = 'A. Determiner',
  DateTime? date,
  String? replacesId,
}) => Determination(
  id: id,
  taxon: taxon,
  qualifier: qualifier,
  specimenCode: specimenCode,
  determiner: determiner,
  date: date ?? DateTime.utc(2026, 4, 1),
  replacesId: replacesId,
);

const String _taxonRef = 'Aves|Turdus|merula';

void main() {
  group('DeterminationDao', () {
    test('a stored Determination reloads with every field intact', () async {
      final database = openDatabase();
      final visit = await _startVisit(database);
      final dao = DeterminationDao(database);
      final determination = _determination();

      await dao.append(
        visitId: visit.id,
        taxonRef: _taxonRef,
        determination: determination,
      );

      final reloaded = await dao.findById(determination.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.id, 'determination-1');
      expect(reloaded.taxon, 'Anthus trivialis');
      expect(reloaded.qualifier, DeterminationQualifier.cf);
      expect(reloaded.specimenCode, 'SP-1');
      expect(reloaded.determiner, 'A. Determiner');
      expect(reloaded.date, DateTime.utc(2026, 4, 1));
      expect(reloaded.replacesId, isNull);
      expect(reloaded, equals(determination));

      expect(await dao.forDetection(visit.id, _taxonRef), [determination]);
    });

    test('inserting a revision links it to the replaced Determination and leaves the replaced row unchanged', () async {
      final database = openDatabase();
      final visit = await _startVisit(database);
      final dao = DeterminationDao(database);
      final original = _determination();

      await dao.append(
        visitId: visit.id,
        taxonRef: _taxonRef,
        determination: original,
      );

      final revision = _determination(
        id: 'determination-2',
        taxon: 'Anthus pratensis',
        qualifier: DeterminationQualifier.aff,
        specimenCode: null,
        determiner: 'B. Determiner',
        date: DateTime.utc(2026, 4, 2),
        replacesId: original.id,
      );
      await dao.append(
        visitId: visit.id,
        taxonRef: _taxonRef,
        determination: revision,
      );

      final reloadedRevision = await dao.findById(revision.id);
      expect(reloadedRevision!.replacesId, original.id);

      final reloadedOriginal = await dao.findById(original.id);
      expect(reloadedOriginal, isNotNull);
      expect(reloadedOriginal!.taxon, original.taxon);
      expect(reloadedOriginal.qualifier, original.qualifier);
      expect(reloadedOriginal.specimenCode, original.specimenCode);
      expect(reloadedOriginal.determiner, original.determiner);
      expect(reloadedOriginal.date, original.date);
      expect(reloadedOriginal.replacesId, isNull);
      expect(reloadedOriginal, equals(original));

      expect(await dao.forDetection(visit.id, _taxonRef), hasLength(2));
    });
  });

  group('migration', () {
    test(
      'migrates a version 9 client schema to version 10 forward-only',
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
CREATE TABLE protocol_versions (
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  protocol_id TEXT NOT NULL,
  version INTEGER NOT NULL,
  document TEXT NOT NULL,
  frozen_at INTEGER,
  PRIMARY KEY (id)
);
''');
              raw.execute('''
CREATE TABLE survey_periods (
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  name TEXT NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
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
              raw.execute('''
CREATE TABLE config_states (
  project_id TEXT NOT NULL,
  version_token TEXT NOT NULL,
  PRIMARY KEY (project_id)
);
''');
              raw.execute('PRAGMA user_version = 9');
            },
          ),
        );
        addTearDown(database.close);

        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 19);

        final tables = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'determinations'",
            )
            .get();
        expect(tables, hasLength(1));

        final visit = await _startVisit(database);
        final dao = DeterminationDao(database);
        final determination = _determination();
        await dao.append(
          visitId: visit.id,
          taxonRef: _taxonRef,
          determination: determination,
        );
        expect(await dao.findById(determination.id), equals(determination));
      },
    );
  });
}
