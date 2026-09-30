import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/sites/sites_map.dart';
import 'package:ibis/features/sites/sites_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/site_dao.dart';

final Uint8List _transparentPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGBgAAAABQABpfZFQAAAAABJRU5ErkJggg==',
);

class _FakeTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPixel);
}

AppDatabase _openDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

Site _site({
  required String id,
  String projectId = 'project-1',
  required SiteGeometry geometry,
}) => Site(
  id: id,
  projectId: projectId,
  geometry: geometry,
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

Widget _wrap(AppDatabase database, Widget child) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets('renders point, line and polygon sites read from the store', (
    tester,
  ) async {
    final database = _openDatabase();
    final dao = SiteDao(database);
    await dao.save(
      _site(id: 'point', geometry: const PointGeometry(LatLng(45.0, 9.0))),
    );
    await dao.save(
      _site(
        id: 'line',
        geometry: const LineGeometry([LatLng(45.0, 9.0), LatLng(45.1, 9.1)]),
      ),
    );
    await dao.save(
      _site(
        id: 'polygon',
        geometry: const PolygonGeometry([
          LatLng(45.0, 9.0),
          LatLng(45.0, 9.1),
          LatLng(45.1, 9.1),
          LatLng(45.0, 9.0),
        ]),
      ),
    );

    await tester.pumpWidget(
      _wrap(
        database,
        SitesMap(projectId: 'project-1', tileProvider: _FakeTileProvider()),
      ),
    );
    await tester.pumpAndSettle();

    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers, hasLength(1));
    expect(markerLayer.markers.single.point, const LatLng(45.0, 9.0));

    final polylineLayer = tester.widget<PolylineLayer<Object>>(
      find.byWidgetPredicate((widget) => widget is PolylineLayer),
    );
    expect(polylineLayer.polylines, hasLength(1));
    expect(polylineLayer.polylines.single.points, const [
      LatLng(45.0, 9.0),
      LatLng(45.1, 9.1),
    ]);

    final polygonLayer = tester.widget<PolygonLayer<Object>>(
      find.byWidgetPredicate((widget) => widget is PolygonLayer),
    );
    expect(polygonLayer.polygons, hasLength(1));
    expect(polygonLayer.polygons.single.points, hasLength(4));
  });

  testWidgets('renders OpenStreetMap tiles', (tester) async {
    final database = _openDatabase();

    await tester.pumpWidget(
      _wrap(
        database,
        SitesMap(projectId: 'project-1', tileProvider: _FakeTileProvider()),
      ),
    );
    await tester.pumpAndSettle();

    final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(
      tileLayer.urlTemplate, // glossary:allow flutter_map API parameter
      contains('openstreetmap.org'),
    );
  });

  testWidgets('does not render sites of another project', (tester) async {
    final database = _openDatabase();
    final dao = SiteDao(database);
    await dao.save(
      _site(
        id: 'mine',
        projectId: 'project-1',
        geometry: const PointGeometry(LatLng(1.0, 1.0)),
      ),
    );
    await dao.save(
      _site(
        id: 'other',
        projectId: 'project-2',
        geometry: const PointGeometry(LatLng(2.0, 2.0)),
      ),
    );

    await tester.pumpWidget(
      _wrap(
        database,
        SitesMap(projectId: 'project-1', tileProvider: _FakeTileProvider()),
      ),
    );
    await tester.pumpAndSettle();

    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers, hasLength(1));
    expect(markerLayer.markers.single.point, const LatLng(1.0, 1.0));
  });

  testWidgets('the map is reachable from the Sites screen', (tester) async {
    final database = _openDatabase();
    await SiteDao(database).save(
      _site(id: 'point', geometry: const PointGeometry(LatLng(45.0, 9.0))),
    );

    await tester.pumpWidget(
      _wrap(database, const SitesScreen(projectId: 'project-1')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SitesMap), findsNothing);

    await tester.tap(find.byKey(const Key('open_sites_map')));
    await tester.pumpAndSettle();

    expect(find.byType(SitesMap), findsOneWidget);
  });
}
