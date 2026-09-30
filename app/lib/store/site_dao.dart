import 'dart:convert';

import '../features/sites/site.dart';
import 'app_database.dart';

class SiteDao {
  SiteDao(this._database);

  final AppDatabase _database;

  Future<void> save(Site site) async {
    await _database
        .into(_database.sites)
        .insertOnConflictUpdate(_toCompanion(site));
  }

  Future<Site?> findById(String id) async {
    final row = await (_database.select(
      _database.sites,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toSite(row);
  }

  SitesCompanion _toCompanion(Site site) => SitesCompanion.insert(
    id: site.id,
    projectId: site.projectId,
    geometry: jsonEncode(site.geometry.toJson()),
    origin: site.origin,
    createdAt: site.createdAt,
  );

  Site _toSite(SiteRow row) => Site(
    id: row.id,
    projectId: row.projectId,
    geometry: SiteGeometry.fromJson(
      jsonDecode(row.geometry) as Map<String, Object?>,
    ),
    origin: row.origin,
    createdAt: row.createdAt.toUtc(),
  );
}
