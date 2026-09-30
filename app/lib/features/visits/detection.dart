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
    this.opportunistic = false,
  }) : assert(
         !opportunistic || detected,
         'An opportunistic Detection is presence-only: it has no not-detected state (INV-003)',
       );

  /// A presence-only Detection of a taxon outside the target list (INV-003).
  /// It is always detected and has no not-detected state.
  const Detection.opportunistic({required this.visitId, required this.taxonRef})
    : detected = true,
      opportunistic = true;

  final String visitId;
  final String taxonRef;
  final bool detected;

  /// Whether this Detection is opportunistic — of a taxon outside the target
  /// list. Opportunistic Detections never imply a non-detection (INV-003).
  final bool opportunistic;

  /// Changes the detected state of a target Detection. An opportunistic
  /// Detection is presence-only, so it is returned unchanged.
  Detection copyWith({bool? detected}) {
    if (opportunistic) return this;
    return Detection(
      visitId: visitId,
      taxonRef: taxonRef,
      detected: detected ?? this.detected,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Detection &&
      other.visitId == visitId &&
      other.taxonRef == taxonRef &&
      other.detected == detected &&
      other.opportunistic == opportunistic;

  @override
  int get hashCode => Object.hash(visitId, taxonRef, detected, opportunistic);
}

/// The target taxa for which [detections] holds no record — the "not
/// recorded" targets of a Visit (INV-002). A Detection with `detected = false`
/// counts as recorded. An opportunistic Detection never records a target: it
/// was not searched for under the Protocol, so it can never imply a
/// non-detection of a target (INV-003).
List<TargetTaxon> unrecordedTargets(
  List<TargetTaxon> targets,
  List<Detection> detections,
) {
  final recorded = <String>{
    for (final detection in detections)
      if (!detection.opportunistic) detection.taxonRef,
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
