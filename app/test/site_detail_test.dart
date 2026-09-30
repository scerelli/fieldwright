import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/sites/site_detail.dart';
import 'package:ibis/features/sites/sites_map.dart';
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
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('shows a site name and names its geometry type', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _openDatabase(),
        SiteDetail(
          site: _site(
            id: 'point',
            geometry: const PointGeometry(LatLng(45.0, 9.0)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Name: Point'), findsOneWidget);
    expect(find.textContaining('Geometry: Point'), findsOneWidget);
    expect(find.textContaining('45.00000'), findsOneWidget);
  });

  testWidgets('names the line and polygon geometry types', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _openDatabase(),
        ListView(
          children: [
            SiteDetail(
              site: _site(
                id: 'line',
                geometry: const LineGeometry([
                  LatLng(45.0, 9.0),
                  LatLng(45.1, 9.1),
                ]),
              ),
            ),
            SiteDetail(
              site: _site(
                id: 'polygon',
                geometry: const PolygonGeometry([
                  LatLng(45.0, 9.0),
                  LatLng(45.0, 9.1),
                  LatLng(45.1, 9.1),
                  LatLng(45.0, 9.0),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Name: Line'), findsOneWidget);
    expect(find.textContaining('Geometry: Line'), findsOneWidget);
    expect(find.text('Name: Polygon'), findsOneWidget);
    expect(find.textContaining('Geometry: Polygon'), findsOneWidget);
  });

  testWidgets('tapping a point site on the map opens its detail', (
    tester,
  ) async {
    final database = _openDatabase();
    await SiteDao(
      database,
    ).save(_site(id: 'point', geometry: const PointGeometry(LatLng(0.0, 0.0))));

    await tester.pumpWidget(
      _wrap(
        database,
        SitesMap(projectId: 'project-1', tileProvider: _FakeTileProvider()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SiteDetail), findsNothing);

    await tester.tap(find.byKey(const Key('site_point')));
    await tester.pumpAndSettle();

    expect(find.byType(SiteDetail), findsOneWidget);
    expect(find.text('Name: Point'), findsOneWidget);
    expect(find.textContaining('Geometry: Point'), findsOneWidget);
  });

  testWidgets('tapping a polygon site on the map opens its detail', (
    tester,
  ) async {
    final database = _openDatabase();
    await SiteDao(database).save(
      _site(
        id: 'polygon',
        geometry: const PolygonGeometry([
          LatLng(-10.0, -10.0),
          LatLng(-10.0, 10.0),
          LatLng(10.0, 10.0),
          LatLng(10.0, -10.0),
          LatLng(-10.0, -10.0),
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

    await tester.tapAt(tester.getCenter(find.byType(SitesMap)));
    await tester.pumpAndSettle();

    expect(find.byType(SiteDetail), findsOneWidget);
    expect(find.text('Name: Polygon'), findsOneWidget);
  });
}
