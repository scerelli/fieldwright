import 'dart:convert';

import 'package:drift/drift.dart';

import '../outbox/config_sync_client.dart';
import '../projects/projects_client.dart';
import '../projects/survey_periods_client.dart';
import '../protocol/protocol.dart';
import '../protocol_versions/protocol_versions_client.dart';
import 'app_database.dart';

/// Persists the configuration a versioned config pull returns into the local
/// drift store (`ARCHITECTURE.md` projects/store modules, ADR-0002, ADR-0011):
/// the Project settings, the Protocol version with its Target list, the Survey
/// periods and the Sites, plus the version token for the next pull.
///
/// The pulled Protocol document is already parsed and validated through the
/// shared [ProtocolDocument] by the time it reaches [apply] (`ProtocolVersion`
/// cannot hold a nonconforming document, ADR-0009); a document that fails that
/// parse is rejected by the pull and never reaches the store. [apply] wraps its
/// writes in one transaction, so a pull is cached whole or not at all.
class ConfigDao {
  ConfigDao(this._database);

  final AppDatabase _database;

  /// Caches [pull] for [projectId], advancing the persisted version token to
  /// the pull's token. A pull that carries no changes is a no-op: it leaves
  /// the cached configuration and the version token untouched.
  Future<void> apply(ConfigPull pull, {required String projectId}) async {
    if (!_hasChanges(pull)) {
      return;
    }
    await _database.transaction(() async {
      final project = pull.project;
      if (project != null) {
        await _writeProject(project);
      }
      final protocolVersion = pull.protocolVersion;
      if (protocolVersion != null) {
        await _writeProtocolVersion(protocolVersion);
      }
      for (final period in pull.surveyPeriods) {
        await _writeSurveyPeriod(period);
      }
      for (final site in pull.sites) {
        await _writeConfigSite(site);
      }
      await _database
          .into(_database.configStates)
          .insertOnConflictUpdate(
            ConfigStatesCompanion.insert(
              projectId: projectId,
              versionToken: pull.versionToken,
            ),
          );
    });
  }

  bool _hasChanges(ConfigPull pull) =>
      pull.project != null ||
      pull.protocolVersion != null ||
      pull.surveyPeriods.isNotEmpty ||
      pull.sites.isNotEmpty;

  /// The cached Project settings, or null when none has been pulled.
  Future<Project?> project(String projectId) async {
    final row = await (_database.select(
      _database.projectConfigs,
    )..where((table) => table.projectId.equals(projectId))).getSingleOrNull();
    return row == null ? null : _toProject(row);
  }

  /// The cached Protocol version with the highest version number, or null.
  Future<ProtocolVersion?> latestProtocolVersion(String projectId) async {
    final row =
        await (_database.select(_database.protocolVersions)
              ..where((table) => table.projectId.equals(projectId))
              ..orderBy([(table) => OrderingTerm.desc(table.version)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toProtocolVersion(row);
  }

  /// The cached Survey periods of a Project.
  Future<List<SurveyPeriod>> surveyPeriods(String projectId) async {
    final rows = await (_database.select(
      _database.surveyPeriods,
    )..where((table) => table.projectId.equals(projectId))).get();
    return rows.map(_toSurveyPeriod).toList(growable: false);
  }

  /// The Sites cached from the config pull, as the transport carries them.
  Future<List<ConfigSite>> sites(String projectId) async {
    final rows = await (_database.select(
      _database.configSites,
    )..where((table) => table.projectId.equals(projectId))).get();
    return rows.map(_toConfigSite).toList(growable: false);
  }

  /// The persisted version token to send as `since` on the next pull, or null
  /// when no pull has been applied yet.
  Future<String?> versionToken(String projectId) async {
    final row = await (_database.select(
      _database.configStates,
    )..where((table) => table.projectId.equals(projectId))).getSingleOrNull();
    return row?.versionToken;
  }

  Future<void> _writeProject(Project project) async {
    await _database
        .into(_database.projectConfigs)
        .insertOnConflictUpdate(
          ProjectConfigsCompanion.insert(
            projectId: project.id,
            name: project.name,
            validationEnabled: project.validationEnabled,
            sensitiveTaxaObfuscation: project.sensitiveTaxaObfuscation,
            taxonomicReferenceId: project.taxonomicReferenceId,
            taxonomicReferenceVersion: project.taxonomicReferenceVersion,
          ),
        );
  }

  Future<void> _writeProtocolVersion(ProtocolVersion protocolVersion) async {
    await _database
        .into(_database.protocolVersions)
        .insertOnConflictUpdate(
          ProtocolVersionsCompanion.insert(
            id: protocolVersion.id,
            projectId: protocolVersion.projectId,
            protocolId: protocolVersion.document.protocolId,
            version: protocolVersion.document.version,
            document: jsonEncode(protocolVersion.document.toJson()),
            frozenAt: Value(protocolVersion.frozenAt),
          ),
        );
  }

  Future<void> _writeSurveyPeriod(SurveyPeriod period) async {
    await _database
        .into(_database.surveyPeriods)
        .insertOnConflictUpdate(
          SurveyPeriodsCompanion.insert(
            id: period.id,
            projectId: period.projectId,
            name: period.name,
            startDate: period.startDate,
            endDate: period.endDate,
          ),
        );
  }

  Future<void> _writeConfigSite(ConfigSite site) async {
    await _database
        .into(_database.configSites)
        .insertOnConflictUpdate(
          ConfigSitesCompanion.insert(
            id: site.id,
            projectId: site.projectId,
            name: Value(site.name),
            geom: Value(site.geom),
            createdAt: Value(site.createdAt),
          ),
        );
  }

  Project _toProject(ProjectConfigRow row) => Project(
    id: row.projectId,
    name: row.name,
    validationEnabled: row.validationEnabled,
    sensitiveTaxaObfuscation: row.sensitiveTaxaObfuscation,
    taxonomicReferenceId: row.taxonomicReferenceId,
    taxonomicReferenceVersion: row.taxonomicReferenceVersion,
  );

  ProtocolVersion _toProtocolVersion(ProtocolVersionRow row) => ProtocolVersion(
    id: row.id,
    projectId: row.projectId,
    document: ProtocolDocument.fromJson(
      jsonDecode(row.document) as Map<String, dynamic>,
    ),
    frozenAt: row.frozenAt?.toUtc(),
  );

  SurveyPeriod _toSurveyPeriod(SurveyPeriodRow row) => SurveyPeriod(
    id: row.id,
    projectId: row.projectId,
    name: row.name,
    startDate: row.startDate,
    endDate: row.endDate,
  );

  ConfigSite _toConfigSite(ConfigSiteRow row) => ConfigSite(
    id: row.id,
    projectId: row.projectId,
    name: row.name,
    geom: row.geom,
    createdAt: row.createdAt?.toUtc(),
  );
}
