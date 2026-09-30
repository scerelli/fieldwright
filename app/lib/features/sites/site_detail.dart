import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'site.dart';

String siteGeometryLabel(AppLocalizations l10n, SiteGeometry geometry) =>
    switch (geometry) {
      PointGeometry() => l10n.siteGeometryPoint,
      LineGeometry() => l10n.siteGeometryLine,
      PolygonGeometry() => l10n.siteGeometryPolygon,
    };

List<LatLng> _vertices(SiteGeometry geometry) => switch (geometry) {
  PointGeometry(:final point) => <LatLng>[point],
  LineGeometry(:final points) => points,
  PolygonGeometry(:final ring) => ring,
};

String _coordinate(LatLng point) =>
    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

class SiteDetail extends StatelessWidget {
  const SiteDetail({super.key, required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final geometryLabel = siteGeometryLabel(l10n, site.geometry);
    final vertices = _vertices(site.geometry);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.siteDetailTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('${l10n.siteDetailName}: $geometryLabel'),
          Text('${l10n.siteDetailGeometry}: $geometryLabel'),
          const SizedBox(height: 8),
          for (final vertex in vertices)
            Text(_coordinate(vertex), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
