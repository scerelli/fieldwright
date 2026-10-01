import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../features/sites/site.dart';
import '../features/visits/determination.dart';
import '../features/visits/evidence.dart';
import '../features/visits/visit.dart';

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

/// A taxon assignment for a Detection (DOMAIN.md › Determination). Append-only
/// (INV-009): a revision is a new row whose `replaces_id` names the
/// Determination it replaces, and no row is ever overwritten. The domain
/// `Determination` carries no Visit or taxon reference of its own, so the
/// owning Detection is stored here as the `(visitId, taxonRef)` pair.
@DataClassName('DeterminationRow')
class Determinations extends Table {
  TextColumn get id => text()();

  TextColumn get visitId => text().references(Visits, #id)();

  TextColumn get taxonRef => text()();

  TextColumn get taxon => text()();

  TextColumn get qualifier => textEnum<DeterminationQualifier>().nullable()();

  TextColumn get specimenCode => text().nullable()();

  TextColumn get determiner => text()();

  DateTimeColumn get date => dateTime()();

  TextColumn get replacesId => text().nullable()();

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

/// The cached settings of a pulled Project (`DOMAIN.md` Project aggregate):
/// validation, sensitive-taxa obfuscation and the pinned Taxonomic reference.
@DataClassName('ProjectConfigRow')
class ProjectConfigs extends Table {
  TextColumn get projectId => text()();

  TextColumn get name => text()();

  BoolColumn get validationEnabled => boolean()();

  BoolColumn get sensitiveTaxaObfuscation => boolean()();

  TextColumn get taxonomicReferenceId => text()();

  TextColumn get taxonomicReferenceVersion => text()();

  @override
  Set<Column<Object>> get primaryKey => {projectId};
}

/// A cached Protocol version (`DOMAIN.md` Protocol version entity, ADR-0009):
/// its immutable document, parsed and validated through the shared
/// `ProtocolDocument` before it is written, is stored as JSON — the Target
/// list travels inside it.
@DataClassName('ProtocolVersionRow')
class ProtocolVersions extends Table {
  TextColumn get id => text()();

  TextColumn get projectId => text()();

  TextColumn get protocolId => text()();

  IntColumn get version => integer()();

  TextColumn get document => text()();

  DateTimeColumn get frozenAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A cached Survey period (`DOMAIN.md` Survey period entity): a named date
/// range, its dates as ISO `YYYY-MM-DD` strings.
@DataClassName('SurveyPeriodRow')
class SurveyPeriods extends Table {
  TextColumn get id => text()();

  TextColumn get projectId => text()();

  TextColumn get name => text()();

  TextColumn get startDate => text()();

  TextColumn get endDate => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A Site as the versioned config pull carries it (`ARCHITECTURE.md` sync
/// compatibility surface, ADR-0011).
///
/// It is the transport row, not the domain `Site`: the config route serves
/// identity, an optional name and geometry as GeoJSON text, but not the origin
/// the domain requires (INV-012), so pulled Sites are cached here rather than
/// in [Sites], which stays for field-created Sites with their origin.
@DataClassName('ConfigSiteRow')
class ConfigSites extends Table {
  TextColumn get id => text()();

  TextColumn get projectId => text()();

  TextColumn get name => text().nullable()();

  TextColumn get geom => text().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The opaque version token to send as `since` on the next config pull
/// (`ARCHITECTURE.md`, ADR-0011), one per Project.
@DataClassName('ConfigStateRow')
class ConfigStates extends Table {
  TextColumn get projectId => text()();

  TextColumn get versionToken => text()();

  @override
  Set<Column<Object>> get primaryKey => {projectId};
}

@DriftDatabase(
  tables: [
    Sites,
    Visits,
    Detections,
    Evidences,
    Determinations,
    Measurements,
    ProjectConfigs,
    ProtocolVersions,
    SurveyPeriods,
    ConfigSites,
    ConfigStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open(String path)
    : super(NativeDatabase.createInBackground(File(path)));

  @override
  int get schemaVersion => 10;

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
        await migrator.createTable(projectConfigs);
        await migrator.createTable(protocolVersions);
        await migrator.createTable(surveyPeriods);
        await migrator.createTable(configSites);
        await migrator.createTable(configStates);
      }
      if (from < 10) {
        await migrator.createTable(determinations);
      }
    },
  );
}
