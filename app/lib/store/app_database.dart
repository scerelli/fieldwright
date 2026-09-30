import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../features/sites/site.dart';

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

@DriftDatabase(tables: [Sites])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open(String path)
    : super(NativeDatabase.createInBackground(File(path)));

  @override
  int get schemaVersion => 3;

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
    },
  );
}
