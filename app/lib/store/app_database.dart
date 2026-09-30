import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../features/sites/site.dart';
import '../features/visits/evidence.dart';
import '../features/visits/visit.dart';
import '../outbox/outbox.dart';

part 'app_database.g.dart';

const appDatabaseFileName = 'ibis.sqlite';

Future<AppDatabase> openAppDatabase() async {
  final directory = await getApplicationSupportDirectory();
  return AppDatabase.open('${directory.path}/$appDatabaseFileName');
}

@DataClassName('SiteRow')
class Sites extends Table {
  TextColumn get id => text()();

  TextColumn get projectId => text()();

  TextColumn get geometry => text()();

  TextColumn get origin => textEnum<SiteOrigin>()();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get locationProvenance => text().nullable()();

  TextColumn get covariates => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('VisitRow')
class Visits extends Table {
  TextColumn get id => text()();

  TextColumn get siteId => text()();

  TextColumn get surveyPeriodId => text()();

  TextColumn get protocolVersionId => text()();

  TextColumn get state => textEnum<VisitState>()();

  DateTimeColumn get effortStartedAt => dateTime()();

  DateTimeColumn get effortEndedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DetectionRow')
class Detections extends Table {
  TextColumn get visitId => text().references(Visits, #id)();

  TextColumn get taxonRef => text()();

  BoolColumn get detected => boolean()();

  BoolColumn get opportunistic =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {visitId, taxonRef};
}

@DataClassName('EvidenceRow')
class Evidences extends Table {
  TextColumn get id => text()();

  TextColumn get visitId => text().references(Visits, #id)();

  TextColumn get taxonRef => text()();

  TextColumn get kind => textEnum<EvidenceKind>()();

  TextColumn get filePath => text()();

  DateTimeColumn get capturedAt => dateTime()();

  TextColumn get contentHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MeasurementRow')
class Measurements extends Table {
  TextColumn get id => text()();

  TextColumn get visitId => text().references(Visits, #id)();

  TextColumn get name => text()();

  TextColumn get value => text()();

  TextColumn get unit => text().nullable()();

  TextColumn get provenance => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OutboxRow')
class OutboxEntries extends Table {
  TextColumn get visitId => text().references(Visits, #id)();

  TextColumn get syncState => textEnum<SyncState>()();

  DateTimeColumn get queuedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {visitId};
}

@DriftDatabase(
  tables: [Sites, Visits, Detections, Evidences, Measurements, OutboxEntries],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open(String path)
    : super(NativeDatabase.createInBackground(File(path)));

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(sites, sites.locationProvenance);
      }
      if (from < 3) {
        await migrator.addColumn(sites, sites.covariates);
      }
      if (from < 4) {
        await migrator.createTable(visits);
      }
      if (from < 5) {
        await migrator.createTable(detections);
      } else if (from < 6) {
        await migrator.addColumn(detections, detections.opportunistic);
      }
      if (from < 7) {
        await migrator.createTable(evidences);
      }
      if (from < 8) {
        await migrator.createTable(measurements);
      }
      if (from < 9) {
        await migrator.createTable(outboxEntries);
      }
    },
  );
}
