import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../protocol/protocol.dart';
import 'measurement.dart';

/// A value taken from the phone sensor that backs a covariate field, with the
/// calibration state it was taken in. An uncalibrated value is marked
/// low-confidence on the Measurement it produces (UX-011).
class SensorValue {
  const SensorValue({
    required this.value,
    this.calibration = CalibrationState.calibrated,
  });

  final double value;

  final CalibrationState calibration;
}

/// The injectable seam over the device sensors that back covariate fields.
///
/// A fake is used in tests, so no platform channel is touched. [read] returns
/// null when this device has no sensor for the field, or it cannot be read:
/// the missing-sensor state the capture screen falls back to manual entry for
/// (UX-011).
abstract interface class SensorService {
  Future<SensorValue?> read(CovariateDefinition field);
}

/// The production [SensorService], backed by `geolocator` (TECH_STACK.md):
/// the phone's location sensor supplies altitude for geographic covariates.
/// A device without a usable location fix, or with the permission denied,
/// reports the sensor as missing so the field falls back to manual entry.
class DeviceSensorService implements SensorService {
  const DeviceSensorService();

  @override
  Future<SensorValue?> read(CovariateDefinition field) async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition();
    return SensorValue(value: position.altitude);
  }
}

/// The device sensor service used by the running app. Tests override this
/// with a fake so no platform channel is touched.
final sensorServiceProvider = Provider<SensorService>(
  (ref) => const DeviceSensorService(),
);
