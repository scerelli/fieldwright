import 'package:latlong2/latlong.dart';

enum SiteOrigin { planned, field }

enum LocationFixMethod { phoneSensor }

class SiteLocationProvenance {
  const SiteLocationProvenance({
    required this.method,
    required this.accuracyMeters,
  });

  final LocationFixMethod method;
  final double accuracyMeters;

  Map<String, Object?> toJson() => {
    'method': method.name,
    'accuracyMeters': accuracyMeters,
  };

  static SiteLocationProvenance fromJson(Map<String, Object?> json) {
    final method = json['method'];
    final accuracy = json['accuracyMeters'];
    if (method is! String || accuracy is! num) {
      throw const FormatException('Malformed site location provenance');
    }
    final parsed = LocationFixMethod.values.firstWhere(
      (candidate) => candidate.name == method,
      orElse: () =>
          throw FormatException('Unsupported location fix method: $method'),
    );
    return SiteLocationProvenance(
      method: parsed,
      accuracyMeters: accuracy.toDouble(),
    );
  }
}

sealed class SiteGeometry {
  const SiteGeometry();

  Map<String, Object?> toJson();

  static SiteGeometry fromJson(Map<String, Object?> json) {
    final type = json['type'];
    final coordinates = json['coordinates'];
    if (type is! String || coordinates is! List) {
      throw const FormatException('Malformed site geometry');
    }
    return switch (type) {
      'Point' => PointGeometry(_position(coordinates)),
      'LineString' => LineGeometry(
        coordinates.map((position) => _position(position)).toList(),
      ),
      'Polygon' => PolygonGeometry(_ring(coordinates.first)),
      _ => throw FormatException('Unsupported site geometry type: $type'),
    };
  }

  static LatLng _position(Object? coordinates) {
    if (coordinates is! List || coordinates.length < 2) {
      throw const FormatException('Malformed site geometry position');
    }
    return LatLng(
      (coordinates[1] as num).toDouble(),
      (coordinates[0] as num).toDouble(),
    );
  }

  static List<LatLng> _ring(Object? ring) {
    if (ring is! List) {
      throw const FormatException('Malformed site geometry ring');
    }
    return ring.map((position) => _position(position)).toList();
  }
}

class PointGeometry extends SiteGeometry {
  const PointGeometry(this.point);

  final LatLng point;

  @override
  Map<String, Object?> toJson() => {
    'type': 'Point',
    'coordinates': [point.longitude, point.latitude],
  };
}

class LineGeometry extends SiteGeometry {
  const LineGeometry(this.points);

  final List<LatLng> points;

  @override
  Map<String, Object?> toJson() => {
    'type': 'LineString',
    'coordinates': [
      for (final point in points) [point.longitude, point.latitude],
    ],
  };
}

class PolygonGeometry extends SiteGeometry {
  const PolygonGeometry(this.ring);

  final List<LatLng> ring;

  @override
  Map<String, Object?> toJson() => {
    'type': 'Polygon',
    'coordinates': [
      [
        for (final point in ring) [point.longitude, point.latitude],
      ],
    ],
  };
}

class Site {
  const Site({
    required this.id,
    required this.projectId,
    required this.geometry,
    required this.origin,
    required this.createdAt,
    this.locationProvenance,
  });

  final String id;
  final String projectId;
  final SiteGeometry geometry;
  final SiteOrigin origin;
  final DateTime createdAt;
  final SiteLocationProvenance? locationProvenance;
}
