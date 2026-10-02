import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/site_dao.dart';

Site buildSite({
  String id = 'site-1',
  String projectId = 'project-1',
  SiteGeometry geometry = const PointGeometry(LatLng(45.0, 9.0)),
  SiteOrigin origin = SiteOrigin.planned,
}) => Site(
  id: id,
  projectId: projectId,
  geometry: geometry,
  origin: origin,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  test('a Site holds a point, line, or polygon geometry and a planned or field origin', () {
    final point = buildSite(geometry: const PointGeometry(LatLng(45.1, 9.2)));
    final line = buildSite(
      geometry: const LineGeometry([LatLng(45.0, 9.0), LatLng(45.1, 9.1)]),
    );
    final polygon = buildSite(
      geometry: const PolygonGeometry([
        LatLng(45.0, 9.0),
        LatLng(45.0, 9.1),
        LatLng(45.1, 9.1),
        LatLng(45.0, 9.0),
      ]),
    );

    expect(point.geometry, isA<PointGeometry>());
    expect(line.geometry, isA<LineGeometry>());
    expect(polygon.geometry, isA<PolygonGeometry>());
    expect(buildSite(origin: SiteOrigin.planned).origin, SiteOrigin.planned);
    expect(buildSite(origin: SiteOrigin.field).origin, SiteOrigin.field);

    expect(
      SiteGeometry.fromJson(point.geometry.toJson()).toJson(),
      point.geometry.toJson(),
    );
    expect(
      SiteGeometry.fromJson(line.geometry.toJson()).toJson(),
      line.geometry.toJson(),
    );
    expect(
      SiteGeometry.fromJson(polygon.geometry.toJson()).toJson(),
      polygon.geometry.toJson(),
    );
  });

  test('a drift database persists created sites across app restarts', () async {
    final directory = Directory.systemTemp.createTempSync('ibis_site_store');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/sites.sqlite';
    final site = buildSite(origin: SiteOrigin.field);

    var database = AppDatabase.open(path);
    await SiteDao(database).save(site);
    await database.close();

    database = AppDatabase.open(path);
    final loaded = await SiteDao(database).findById(site.id);
    await database.close();

    expect(loaded, isNotNull);
    expect(loaded!.id, site.id);
    expect(loaded.projectId, site.projectId);
    expect(loaded.origin, SiteOrigin.field);
    expect(loaded.createdAt, site.createdAt);
    expect(loaded.geometry.toJson(), site.geometry.toJson());
  });

  test('applies the drift schema through a forward-only migration', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], 17);

    await SiteDao(database).save(buildSite());

    final sites = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'sites'",
        )
        .get();
    expect(sites, hasLength(1));
  });
}
