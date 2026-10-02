import 'dart:convert';

import '../features/sites/site.dart';
import '../outbox/config_sync_client.dart';
import '../projects/projects_client.dart';
import '../projects/survey_periods_client.dart';
import '../protocol_versions/protocol_versions_client.dart';
import 'app_database.dart';
import 'project_dao.dart';

/// Persists the configuration a versioned config pull returns into the local
/// Project aggregate (`ARCHITECTURE.md` projects/store modules, ADR-0002,
/// ADR-0011, ADR-0014): the Project root, the Protocol version with its Target
/// list, the Survey periods and the Sites, plus the version token for the next
/// pull.
///
/// It writes the same `projects`, `protocol_versions`, `survey_periods` and
/// `sites` tables local creation does — through [ProjectDao] — so a joined
/// Project and a locally-created one are one representation, with no separate
/// pull-cache copy. The pulled Protocol document is already parsed and
/// validated through the shared [ProtocolDocument] by the time it reaches
/// [apply] (`ProtocolVersion` cannot hold a nonconforming document, ADR-0009);
/// a document that fails that parse is rejected by the pull and never reaches
/// the store. [apply] wraps its writes in one transaction, so a pull is applied
/// whole or not at all.
class ConfigDao {
  ConfigDao(this._database) : _projects = ProjectDao(_database);

  final AppDatabase _database;
  final ProjectDao _projects;

  /// Applies [pull] for [projectId], advancing the persisted version token to
  /// the pull's token when the whole pull could be represented. A pull that
  /// carries no changes is a no-op: it leaves the stored configuration and the
  /// version token untouched.
  ///
  /// The version token is a high-water mark the server advances by change
  /// time, so it must only move past data the client actually persisted. When
  /// the pull carries a Site the client cannot represent, [apply] writes the
  /// rest of the pull but leaves the token where it was, so the next pull
  /// re-sends that Site rather than dropping it forever.
  Future<void> apply(ConfigPull pull, {required String projectId}) async {
    if (!_hasChanges(pull)) {
      return;
    }
    await _database.transaction(() async {
      final project = pull.project;
      if (project != null) {
        await _projects.save(project);
      }
      final protocolVersion = pull.protocolVersion;
      if (protocolVersion != null) {
        await _projects.saveProtocolVersion(protocolVersion);
      }
      for (final period in pull.surveyPeriods) {
        await _projects.saveSurveyPeriod(period);
      }
      var allSitesRepresented = true;
      for (final site in pull.sites) {
        if (!await _writeConfigSite(site)) {
          allSitesRepresented = false;
        }
      }
      if (allSitesRepresented) {
        await _database
            .into(_database.configStates)
            .insertOnConflictUpdate(
              ConfigStatesCompanion.insert(
                projectId: projectId,
                versionToken: pull.versionToken,
              ),
            );
      }
    });
  }

  bool _hasChanges(ConfigPull pull) =>
      pull.project != null ||
      pull.protocolVersion != null ||
      pull.surveyPeriods.isNotEmpty ||
      pull.sites.isNotEmpty;

  /// The stored Project, or null when none has been written.
  Future<Project?> project(String projectId) => _projects.findById(projectId);

  /// The stored Protocol version with the highest version number, or null.
  Future<ProtocolVersion?> latestProtocolVersion(String projectId) =>
      _projects.latestProtocolVersion(projectId);

  /// The stored Protocol version with [protocolVersionId], or null when it has
  /// not been pulled. A Visit references the exact version it was captured
  /// under, so submission reads it by id — never the latest (INV-006, INV-007).
  Future<ProtocolVersion?> protocolVersion(String protocolVersionId) =>
      _projects.protocolVersion(protocolVersionId);

  /// The Survey periods of a Project.
  Future<List<SurveyPeriod>> surveyPeriods(String projectId) =>
      _projects.surveyPeriods(projectId);

  /// The Sites of a Project, as the config pull carries them. Read from the
  /// same `sites` table local creation writes.
  Future<List<ConfigSite>> sites(String projectId) async {
    final rows = await (_database.select(
      _database.sites,
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

  /// Writes a pulled Site into the unified `sites` table as a domain `Site`,
  /// returning whether it was persisted.
  ///
  /// The pull carries no `origin`; a Site defined by a Project's creator is
  /// planned (INV-012). The transport `name` is preserved alongside it. A Site
  /// the client cannot represent is not persisted: one with no geometry is not
  /// yet a domain `Site`, and one whose geometry the client does not model (an
  /// unsupported type or malformed text) is ignored, not fatal (ADR-0011).
  Future<bool> _writeConfigSite(ConfigSite site) async {
    final geom = site.geom;
    if (geom == null) {
      return false;
    }
    final geometry = _parseGeometry(geom);
    if (geometry == null) {
      return false;
    }
    await _projects.savePulledSite(
      Site(
        id: site.id,
        projectId: site.projectId,
        geometry: geometry,
        origin: SiteOrigin.planned,
        createdAt: (site.createdAt ?? DateTime.now()).toUtc(),
      ),
      name: site.name,
    );
    return true;
  }

  /// Parses a pulled GeoJSON geometry, or returns null when the client does
  /// not model it — an unsupported type, malformed coordinates, or text that
  /// is not a GeoJSON object. Unknown geometry is ignored like any other field
  /// the client does not model (ADR-0011), never fatal to the pull.
  SiteGeometry? _parseGeometry(String geom) {
    try {
      final decoded = jsonDecode(geom);
      if (decoded is! Map) {
        return null;
      }
      return SiteGeometry.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on StateError {
      return null;
    }
  }

  ConfigSite _toConfigSite(SiteRow row) => ConfigSite(
    id: row.id,
    projectId: row.projectId,
    name: row.name,
    geom: row.geometry,
    createdAt: row.createdAt.toUtc(),
  );
}
