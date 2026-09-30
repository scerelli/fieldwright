import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../store/site_dao.dart';
import 'site.dart';

class LocationFix {
  const LocationFix({
    required this.position,
    required this.method,
    required this.accuracyMeters,
  });

  final LatLng position;
  final LocationFixMethod method;
  final double accuracyMeters;
}

abstract interface class LocationService {
  Future<LocationFix> currentLocation();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationFix> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException('Location permission denied');
    }
    final position = await Geolocator.getCurrentPosition();
    return LocationFix(
      position: LatLng(position.latitude, position.longitude),
      method: LocationFixMethod.phoneSensor,
      accuracyMeters: position.accuracy,
    );
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

Future<Site> createFieldSite({
  required LocationService locationService,
  required SiteDao dao,
  required String projectId,
  DateTime? now,
}) async {
  final fix = await locationService.currentLocation();
  final site = Site(
    id: _newSiteId(),
    projectId: projectId,
    geometry: PointGeometry(fix.position),
    origin: SiteOrigin.field,
    createdAt: (now ?? DateTime.now()).toUtc(),
    locationProvenance: SiteLocationProvenance(
      method: fix.method,
      accuracyMeters: fix.accuracyMeters,
    ),
  );
  await dao.save(site);
  return site;
}

final Random _random = Random();

String _newSiteId() {
  final microseconds = DateTime.now().toUtc().microsecondsSinceEpoch;
  final suffix = _random.nextInt(1 << 32).toRadixString(16);
  return '${microseconds.toRadixString(16)}-$suffix';
}
