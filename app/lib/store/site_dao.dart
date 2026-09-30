import 'dart:convert';

import 'package:drift/drift.dart';

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
