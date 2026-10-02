import 'dart:convert';

import 'package:drift/drift.dart';

import '../features/sites/site.dart';
import 'app_database.dart';

class SiteDao {
  SiteDao(this._database);

  final AppDatabase _database;

  /// Writes [site], keeping the pulled [name] when it already has one.
  ///
  /// A caller that supplies no [name] — a Site created on the device — leaves
  /// the column untouched on conflict, so a later local save cannot erase the
  /// name a config pull stored.
  Future<void> save(Site site, {String? name}) async {
    await _database
        .into(_database.sites)
        .insertOnConflictUpdate(_toCompanion(site, name: name));
  }

  Future<Site?> findById(String id) async {
    final row = await (_database.select(
      _database.sites,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toSite(row);
  }

  /// The Sites of one Project, in no particular order.
  Future<List<Site>> findByProject(String projectId) async {
    final rows = await (_database.select(
      _database.sites,
    )..where((table) => table.projectId.equals(projectId))).get();
    return rows.map(_toSite).toList(growable: false);
  }

  SitesCompanion _toCompanion(Site site, {String? name}) =>
      SitesCompanion.insert(
        id: site.id,
        projectId: site.projectId,
        name: name == null ? const Value.absent() : Value(name),
        geometry: jsonEncode(site.geometry.toJson()),
        origin: site.origin,
        createdAt: site.createdAt,
        locationProvenance: site.locationProvenance == null
            ? const Value(null)
            : Value(jsonEncode(site.locationProvenance!.toJson())),
        covariates: site.covariates.isEmpty
            ? const Value(null)
            : Value(
                jsonEncode([
                  for (final covariate in site.covariates) covariate.toJson(),
                ]),
              ),
      );

  Site _toSite(SiteRow row) => Site(
    id: row.id,
    projectId: row.projectId,
    geometry: SiteGeometry.fromJson(
      jsonDecode(row.geometry) as Map<String, Object?>,
    ),
    origin: row.origin,
    createdAt: row.createdAt.toUtc(),
    locationProvenance: row.locationProvenance == null
        ? null
        : SiteLocationProvenance.fromJson(
            jsonDecode(row.locationProvenance!) as Map<String, Object?>,
          ),
    covariates: row.covariates == null
        ? const []
        : [
            for (final item in jsonDecode(row.covariates!) as List)
              SiteCovariate.fromJson((item as Map).cast<String, Object?>()),
          ],
  );
}
