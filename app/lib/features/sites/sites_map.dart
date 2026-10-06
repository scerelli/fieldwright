import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../store/database_provider.dart';
import 'map_tile_cache.dart';
import 'site.dart';
import 'site_detail.dart';

const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// The open Project's Sites with their full record — covariates and location
/// provenance included (`SiteDao.findByProject`). This one provider backs the
/// Sites tab, the Visits tab and [SitesMap], so adding a Site invalidates a
/// single cache and every reader sees it (`INV-012`).
final projectSitesProvider = FutureProvider.family<List<Site>, String>(
  (ref, projectId) => ref.watch(siteDaoProvider).findByProject(projectId),
);

class SitesMap extends ConsumerStatefulWidget {
  const SitesMap({super.key, required this.projectId, this.tileProvider});

  final String projectId;
  final TileProvider? tileProvider;

  @override
  ConsumerState<SitesMap> createState() => _SitesMapState();
}

class _SitesMapState extends ConsumerState<SitesMap> {
  final LayerHitNotifier<String> _polylineHits = ValueNotifier(null);
  final LayerHitNotifier<String> _polygonHits = ValueNotifier(null);

  @override
  void dispose() {
    _polylineHits.dispose();
    _polygonHits.dispose();
    super.dispose();
  }

  void _openSite(Site site) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SiteDetail(site: site),
    );
  }

  void _openTappedSite(LayerHitNotifier<String> hits, List<Site> sites) {
    final hitValues = hits.value?.hitValues;
    if (hitValues == null || hitValues.isEmpty) return;
    final id = hitValues.first;
    for (final site in sites) {
      if (site.id == id) {
        _openSite(site);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sites =
        ref.watch(projectSitesProvider(widget.projectId)).value ??
        const <Site>[];

    return FlutterMap(
      options: const MapOptions(initialCenter: LatLng(0, 0), initialZoom: 2),
      children: [
        TileLayer(
          urlTemplate: _osmTileUrl, // glossary:allow flutter_map parameter
          userAgentPackageName: 'org.ibis.ibis',
          tileProvider:
              widget.tileProvider ??
              NetworkTileProvider(
                cachingProvider: ref.watch(mapTileCacheProvider),
              ),
        ),
        ..._siteOverlays(Theme.of(context).colorScheme, sites),
      ],
    );
  }

  List<Widget> _siteOverlays(ColorScheme colorScheme, List<Site> sites) {
    final markers = <Marker>[];
    final polylines = <Polyline<String>>[];
    final polygons = <Polygon<String>>[];

    for (final site in sites) {
      switch (site.geometry) {
        case PointGeometry(:final point):
          markers.add(
            Marker(
              point: point,
              width: 48,
              height: 48,
              child: GestureDetector(
                key: Key('site_${site.id}'),
                onTap: () => _openSite(site),
                child: Icon(Icons.place, color: colorScheme.primary),
              ),
            ),
          );
        case LineGeometry(:final points):
          polylines.add(
            Polyline(
              points: points,
              strokeWidth: 4,
              color: colorScheme.primary,
              hitValue: site.id,
            ),
          );
        case PolygonGeometry(:final ring):
          polygons.add(
            Polygon(
              points: ring,
              color: colorScheme.primary.withValues(alpha: 0.3),
              borderColor: colorScheme.primary,
              borderStrokeWidth: 2,
              hitValue: site.id,
            ),
          );
      }
    }

    return [
      if (polygons.isNotEmpty)
        GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () => _openTappedSite(_polygonHits, sites),
          child: PolygonLayer<String>(
            polygons: polygons,
            hitNotifier: _polygonHits,
          ),
        ),
      if (polylines.isNotEmpty)
        GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () => _openTappedSite(_polylineHits, sites),
          child: PolylineLayer<String>(
            polylines: polylines,
            hitNotifier: _polylineHits,
          ),
        ),
      if (markers.isNotEmpty) MarkerLayer(markers: markers),
    ];
  }
}
