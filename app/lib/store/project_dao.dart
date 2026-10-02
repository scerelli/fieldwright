import 'dart:convert';

import 'package:drift/drift.dart';

import '../features/sites/site.dart';
import '../projects/projects_client.dart';
import '../projects/survey_periods_client.dart';
import '../protocol/protocol.dart';
import '../protocol_versions/protocol_versions_client.dart';
import 'app_database.dart';
import 'site_dao.dart';

/// Owns the local Project aggregate (`ARCHITECTURE.md` client local store,
/// ADR-0002, ADR-0014): one row in `projects` with its `protocol_versions`,
/// `survey_periods` and `sites`.
///
/// It is the single writer the accountless journey and the config pull share,
/// so a Project created with no account and one joined from the server are the
/// same representation. A Project's identity is assigned at creation and never
/// changes — linking a locally-created Project preserves its client-assigned id
/// (INV-015).
class ProjectDao {
  ProjectDao(this._database) : _sites = SiteDao(_database);

  final AppDatabase _database;
  final SiteDao _sites;

  /// Writes (or replaces) the Project's root row, keeping its identity.
  Future<void> save(Project project) async {
    await _database
        .into(_database.projects)
        .insertOnConflictUpdate(
          ProjectsCompanion.insert(
            id: project.id,
            name: project.name,
            validationEnabled: project.validationEnabled,
            sensitiveTaxaObfuscation: project.sensitiveTaxaObfuscation,
            taxonomicReferenceId: project.taxonomicReferenceId,
            taxonomicReferenceVersion: project.taxonomicReferenceVersion,
          ),
        );
  }

  /// The Project with [id], or null when none is stored.
  Future<Project?> findById(String id) async {
    final row = await (_database.select(
      _database.projects,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toProject(row);
  }

  Future<void> saveProtocolVersion(ProtocolVersion version) async {
    await _database
        .into(_database.protocolVersions)
        .insertOnConflictUpdate(
          ProtocolVersionsCompanion.insert(
            id: version.id,
            projectId: version.projectId,
            protocolId: version.document.protocolId,
            version: version.document.version,
            document: jsonEncode(version.document.toJson()),
            frozenAt: Value(version.frozenAt),
          ),
        );
  }

  /// The Protocol version with [id], or null when it has not been stored.
  Future<ProtocolVersion?> protocolVersion(String id) async {
    final row = await (_database.select(
      _database.protocolVersions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toProtocolVersion(row);
  }

  /// The Project's Protocol version with the highest version number, or null.
  Future<ProtocolVersion?> latestProtocolVersion(String projectId) async {
    final row =
        await (_database.select(_database.protocolVersions)
              ..where((table) => table.projectId.equals(projectId))
              ..orderBy([(table) => OrderingTerm.desc(table.version)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toProtocolVersion(row);
  }

  Future<void> saveSurveyPeriod(SurveyPeriod period) async {
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

  /// The Survey periods of a Project.
  Future<List<SurveyPeriod>> surveyPeriods(String projectId) async {
    final rows = await (_database.select(
      _database.surveyPeriods,
    )..where((table) => table.projectId.equals(projectId))).get();
    return rows.map(_toSurveyPeriod).toList(growable: false);
  }

  /// Writes a Site into the Project aggregate. [name] is the name the config
  /// pull carries; a Site created on the device has none.
  Future<void> saveSite(Site site, {String? name}) =>
      _sites.save(site, name: name);

  /// The Sites of a Project.
  Future<List<Site>> sites(String projectId) => _sites.findByProject(projectId);

  Project _toProject(ProjectRow row) => Project(
    id: row.id,
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
}
