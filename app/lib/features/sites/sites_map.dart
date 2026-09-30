import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../store/app_database.dart';
import '../../store/database_provider.dart';
import 'site.dart';

const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

final projectSitesProvider = FutureProvider.family<List<Site>, String>((
  ref,
  projectId,
) async {
  final database = ref.watch(databaseProvider);
  final rows = await database.select(database.sites).get();
  return rows
      .where((row) => row.projectId == projectId)
      .map(_siteFromRow)
      .toList(growable: false);
});

Site _siteFromRow(SiteRow row) => Site(
  id: row.id,
  projectId: row.projectId,
  geometry: SiteGeometry.fromJson(
    jsonDecode(row.geometry) as Map<String, Object?>,
  ),
  origin: row.origin,
  createdAt: row.createdAt.toUtc(),
);

class SitesMap extends ConsumerWidget {
  const SitesMap({super.key, required this.projectId, this.tileProvider});

  final String projectId;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites =
        ref.watch(projectSitesProvider(projectId)).value ?? const <Site>[];

    return FlutterMap(
      options: const MapOptions(initialCenter: LatLng(0, 0), initialZoom: 2),
      children: [
        TileLayer(
          urlTemplate: _osmTileUrl, // glossary:allow flutter_map parameter
          userAgentPackageName: 'org.ibis.ibis',
          tileProvider: tileProvider ?? NetworkTileProvider(),
        ),
        ..._siteOverlays(Theme.of(context).colorScheme, sites),
      ],
    );
  }
}

List<Widget> _siteOverlays(ColorScheme colorScheme, List<Site> sites) {
  final markers = <Marker>[];
  final polylines = <Polyline>[];
  final polygons = <Polygon>[];

  for (final site in sites) {
    switch (site.geometry) {
      case PointGeometry(:final point):
        markers.add(
          Marker(
            point: point,
            width: 40,
            height: 40,
            child: Icon(Icons.place, color: colorScheme.primary),
          ),
        );
      case LineGeometry(:final points):
        polylines.add(
          Polyline(points: points, strokeWidth: 4, color: colorScheme.primary),
        );
      case PolygonGeometry(:final ring):
        polygons.add(
          Polygon(
            points: ring,
            color: colorScheme.primary.withValues(alpha: 0.3),
            borderColor: colorScheme.primary,
            borderStrokeWidth: 2,
          ),
        );
    }
  }

  return [
    if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
    if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
    if (markers.isNotEmpty) MarkerLayer(markers: markers),
  ];
}
