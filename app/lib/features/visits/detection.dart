import '../../protocol/protocol.dart';

/// The record that one taxon was detected, or searched for and not detected,
/// in one Visit (DOMAIN.md › Detection). A non-detection is a Detection with
/// [detected] false — never a missing record. A target taxon with no Detection
/// at all is "not recorded", a state distinct from "not detected" (INV-002).
///
/// Identity is within its Visit: the pair of [visitId] and [taxonRef].
class Detection {
  const Detection({
    required this.visitId,
    required this.taxonRef,
    required this.detected,
  });

  final String visitId;
  final String taxonRef;
  final bool detected;

  Detection copyWith({bool? detected}) => Detection(
    visitId: visitId,
    taxonRef: taxonRef,
    detected: detected ?? this.detected,
  );

  @override
  bool operator ==(Object other) =>
      other is Detection &&
      other.visitId == visitId &&
      other.taxonRef == taxonRef &&
      other.detected == detected;

  @override
  int get hashCode => Object.hash(visitId, taxonRef, detected);
}

/// The target taxa for which [detections] holds no record — the "not
/// recorded" targets of a Visit (INV-002). A Detection with `detected = false`
/// counts as recorded.
List<TargetTaxon> unrecordedTargets(
  List<TargetTaxon> targets,
  List<Detection> detections,
) {
  final recorded = <String>{
    for (final detection in detections) detection.taxonRef,
  };
  return <TargetTaxon>[
    for (final target in targets)
      if (!recorded.contains(target.taxonRef)) target,
  ];
}

/// Whether every target taxon has a Detection, so the Visit may be submitted
/// (INV-002).
bool allTargetsRecorded(
  List<TargetTaxon> targets,
  List<Detection> detections,
) => unrecordedTargets(targets, detections).isEmpty;
