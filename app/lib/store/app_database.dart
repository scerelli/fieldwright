import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../features/sites/site.dart';
import '../features/visits/determination.dart';
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

  /// The name the config pull carries for a Site, or null for a Site created
  /// on the device or one the server never named.
  TextColumn get name => text().nullable()();

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

  /// The Visit's recorded observers, the `observers` Sampling-effort field the
  /// Protocol version may require, as a JSON-encoded list of names (INV-005).
  /// Null for a Visit captured before the client schema recorded them.
  TextColumn get effortObservers => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DetectionRow')
class Detections extends Table {
  TextColumn get visitId => text().references(Visits, #id)();

  TextColumn get taxonRef => text()();

  BoolColumn get detected => boolean()();

  TextColumn get method => text().nullable()();

  IntColumn get count => integer().nullable()();

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

  /// The content-addressed key the media API returned when this Evidence was
  /// uploaded, or null while it has never been uploaded. It is the transport
  /// reference the submission's evidence manifest carries.
  TextColumn get storageKey => text().nullable()();

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

@DataClassName('OutboxRow')
class OutboxEntries extends Table {
  TextColumn get visitId => text().references(Visits, #id)();

  TextColumn get syncState => textEnum<SyncState>()();

  DateTimeColumn get queuedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {visitId};
}

/// The local Project aggregate's root row (`DOMAIN.md` Project aggregate,
/// `ARCHITECTURE.md` client local store): a Project's settings and its pinned
/// Taxonomic reference. Its identity is assigned at creation — a client UUIDv7
/// for a Project created offline, the server id for one created online — and
/// never changes (INV-015). Written by local creation and the config pull alike.
@DataClassName('ProjectRow')
class Projects extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  BoolColumn get validationEnabled => boolean()();

  BoolColumn get sensitiveTaxaObfuscation => boolean()();

  TextColumn get taxonomicReferenceId => text()();

  TextColumn get taxonomicReferenceVersion => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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

/// The opaque version token to send as `since` on the next config pull
/// (`ARCHITECTURE.md`, ADR-0011), one per Project.
@DataClassName('ConfigStateRow')
class ConfigStates extends Table {
  TextColumn get projectId => text()();

  TextColumn get versionToken => text()();

  @override
  Set<Column<Object>> get primaryKey => {projectId};
}

/// The signed-in person and their auth cookie, kept so a relaunch does not
/// sign them out (`ARCHITECTURE.md` store module). A single row keyed by a
/// fixed id holds the current sign-in; saving replaces it and clearing deletes
/// it.
@DataClassName('AuthSessionRow') /* glossary:allow auth session */
class AuthSessions /* glossary:allow auth session */ extends Table {
  /// The fixed key of the single persisted sign-in.
  TextColumn get id => text()();

  TextColumn get personId => text()();

  TextColumn get email => text()();

  TextColumn get name => text()();

  TextColumn get cookie => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Sites,
    Visits,
    Detections,
    Evidences,
    Determinations,
    Measurements,
    Projects,
    ProtocolVersions,
    SurveyPeriods,
    ConfigStates,
    AuthSessions, // glossary:allow auth session
    OutboxEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open(String path)
    : super(NativeDatabase.createInBackground(File(path)));

  @override
  int get schemaVersion => 16;

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
      } else if (from < 14) {
        await migrator.addColumn(visits, visits.effortObservers);
      }
      if (from < 5) {
        await migrator.createTable(detections);
      } else {
        if (from < 6) {
          await migrator.addColumn(detections, detections.opportunistic);
        }
        if (from < 12) {
          await migrator.addColumn(detections, detections.method);
          await migrator.addColumn(detections, detections.count);
        }
      }
      if (from < 7) {
        await migrator.createTable(evidences);
      } else if (from < 13) {
        await migrator.addColumn(evidences, evidences.storageKey);
      }
      if (from < 8) {
        await migrator.createTable(measurements);
      }
      if (from < 9) {
        // Pre-pull-cache era: create the unified Project aggregate tables
        // directly, replacing the old `project_configs`/`config_sites` pair.
        await migrator.createTable(projects);
        await migrator.createTable(protocolVersions);
        await migrator.createTable(surveyPeriods);
        await migrator.createTable(configStates);
      }
      if (from < 10) {
        await migrator.createTable(determinations);
      }
      if (from < 11) {
        await migrator.createTable(outboxEntries);
      }
      if (from < 15) {
        await migrator.createTable(
          authSessions, // glossary:allow auth session
        );
      }
      if (from >= 9 && from < 16) {
        // The pull-cache era stored the Project root in `project_configs`;
        // move it into the unified `projects` table (INV-015).
        await migrator.createTable(projects);
        if (await _hasTable('project_configs')) {
          await customStatement(
            'INSERT OR REPLACE INTO projects (id, name, validation_enabled, '
            'sensitive_taxa_obfuscation, taxonomic_reference_id, '
            'taxonomic_reference_version) SELECT project_id, name, '
            'validation_enabled, sensitive_taxa_obfuscation, '
            'taxonomic_reference_id, taxonomic_reference_version '
            'FROM project_configs',
          );
        }
      }
      if (from < 16) {
        final hasSites = await _hasTable('sites');
        if (hasSites) {
          await migrator.addColumn(sites, sites.name);
        }
        if (from >= 9) {
          if (hasSites && await _hasTable('config_sites')) {
            // `config_sites` allowed a null `geom` and `created_at`; the
            // unified `sites` requires both. A row with no geometry cannot
            // become a domain Site (geometry cannot be fabricated), so it is
            // dropped; a missing `created_at` is coalesced to now.
            await customStatement(
              "INSERT OR REPLACE INTO sites (id, project_id, geometry, "
              "origin, created_at, name) SELECT id, project_id, geom, "
              "'planned', COALESCE(created_at, CAST(strftime('%s', 'now') "
              'AS INTEGER)), name FROM config_sites WHERE geom IS NOT NULL',
            );
            await customStatement('DROP TABLE IF EXISTS config_sites');
          }
          await customStatement('DROP TABLE IF EXISTS project_configs');
        }
      }
    },
  );

  /// Whether [name] is a table in the connected SQLite database, used to keep
  /// the v16 migration forward-only over databases that predate a table.
  Future<bool> _hasTable(String name) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
    ).get();
    return rows.isNotEmpty;
  }
}
