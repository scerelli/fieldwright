/// How a [Measurement] was obtained, the method every Measurement's
/// [Provenance] carries (DOMAIN.md › Provenance): a phone sensor, a field
/// instrument, or a visual estimate.
enum ProvenanceMethod { phoneSensor, fieldInstrument, visualEstimate }

/// Whether the sensor or instrument behind a Measurement was calibrated when
/// it was read. An uncalibrated value is low-confidence.
enum CalibrationState { calibrated, uncalibrated }

/// How a [Measurement] was obtained (DOMAIN.md › Provenance): the method, plus
/// the device or instrument, its calibration state, the uncertainty, the
/// observer, and the time. Every Measurement carries it — a value without a
/// method is invalid (INV-010).
class Provenance {
  const Provenance({
    required this.method,
    this.calibration = CalibrationState.calibrated,
    this.instrument,
    this.uncertainty,
    this.observer,
    this.recordedAt,
  });

  /// Phone sensor, field instrument, or visual estimate.
  final ProvenanceMethod method;

  /// Calibration state of the sensor or instrument that produced the value.
  final CalibrationState calibration;

  /// Device or instrument make and model.
  final String? instrument;

  /// Uncertainty of the value, in the Measurement's unit.
  final double? uncertainty;

  /// The person who took the Measurement.
  final String? observer;

  /// When the Measurement was taken.
  final DateTime? recordedAt;

  Map<String, Object?> toJson() => {
    'method': method.name,
    'calibration': calibration.name,
    'instrument': instrument,
    'uncertainty': uncertainty,
    'observer': observer,
    'recordedAt': recordedAt?.toUtc().toIso8601String(),
  };

  static Provenance fromJson(Map<String, Object?> json) {
    final method = json['method'];
    if (method is! String) {
      throw const FormatException('Malformed provenance');
    }
    final parsedMethod = ProvenanceMethod.values.firstWhere(
      (candidate) => candidate.name == method,
      orElse: () =>
          throw FormatException('Unsupported provenance method: $method'),
    );
    final calibration = json['calibration'];
    final parsedCalibration = calibration == null
        ? CalibrationState.calibrated
        : CalibrationState.values.firstWhere(
            (candidate) => candidate.name == calibration,
            orElse: () => throw FormatException(
              'Unsupported calibration state: $calibration',
            ),
          );
    final recordedAt = json['recordedAt'];
    return Provenance(
      method: parsedMethod,
      calibration: parsedCalibration,
      instrument: json['instrument'] as String?,
      uncertainty: (json['uncertainty'] as num?)?.toDouble(),
      observer: json['observer'] as String?,
      recordedAt: recordedAt is String
          ? DateTime.parse(recordedAt).toUtc()
          : null,
    );
  }
}

/// A value with a unit and its [Provenance] (DOMAIN.md › Measurement), the
/// value of a Visit or Site covariate. A Measurement always carries a
/// provenance whose method is set; [buildMeasurement] rejects one without.
class Measurement {
  const Measurement({
    required this.name,
    required this.value,
    required this.provenance,
    this.unit,
  });

  /// The covariate definition this value belongs to.
  final String name;

  /// The recorded value. Stored as text so a numeric sensor value and a
  /// textual covariate value share one shape.
  final String value;

  final String? unit;

  final Provenance provenance;

  /// An uncalibrated sensor or instrument value is low-confidence and is
  /// shown as such (UX-011).
  bool get isLowConfidence =>
      provenance.calibration == CalibrationState.uncalibrated;

  Map<String, Object?> toJson() => {
    'name': name,
    'value': value,
    'unit': unit,
    'provenance': provenance.toJson(),
  };

  static Measurement fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final value = json['value'];
    final unit = json['unit'];
    final provenance = json['provenance'];
    if (name is! String ||
        value is! String ||
        (unit != null && unit is! String) ||
        provenance is! Map) {
      throw const FormatException('Malformed measurement');
    }
    return Measurement(
      name: name,
      value: value,
      unit: unit as String?,
      provenance: Provenance.fromJson(provenance.cast<String, Object?>()),
    );
  }
}

/// Builds a [Measurement] from an entered [value] and its provenance method.
/// A value without a method is invalid (INV-010) and is rejected as null.
Measurement? buildMeasurement({
  required String name,
  required String value,
  required String? unit,
  required ProvenanceMethod? method,
  CalibrationState calibration = CalibrationState.calibrated,
  String? instrument,
  double? uncertainty,
  String? observer,
  DateTime? recordedAt,
}) {
  if (method == null) return null;
  return Measurement(
    name: name,
    value: value,
    unit: unit,
    provenance: Provenance(
      method: method,
      calibration: calibration,
      instrument: instrument,
      uncertainty: uncertainty,
      observer: observer,
      recordedAt: recordedAt,
    ),
  );
}
