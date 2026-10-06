import '../../protocol/protocol.dart';

/// The record that one taxon was detected, or searched for and not detected,
/// in one Visit (DOMAIN.md › Detection). A non-detection is a Detection with
/// [detected] false — never a missing record. A target taxon with no Detection
/// at all is "not recorded", a state distinct from "not detected" (INV-019).
///
/// Identity is within its Visit: the pair of [visitId] and [taxonRef].
class Detection {
  const Detection({
    required this.visitId,
    required this.taxonRef,
    required this.detected,
    this.method,
    this.count,
    this.opportunistic = false,
  }) : assert(
         !opportunistic || detected,
         'An opportunistic Detection is presence-only: it has no not-detected state (INV-003)',
       );

  /// A presence-only Detection of a taxon outside the target list (INV-003).
  /// It is always detected and has no not-detected state.
  const Detection.opportunistic({
    required this.visitId,
    required this.taxonRef,
    this.method,
    this.count,
  }) : detected = true,
       opportunistic = true;

  final String visitId;
  final String taxonRef;
  final bool detected;

  /// The id of the [DetectionMethod] the Detection was made with — one of the
  /// `detectionMethods` its Protocol version declares (GLOSSARY.md › Detection
  /// method). Null only on a row persisted before the client schema recorded
  /// methods; a new Detection is never stored without one.
  final String? method;

  /// The number of individuals detected, when the survey counted them.
  final int? count;

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
      method: method,
      count: count,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Detection &&
      other.visitId == visitId &&
      other.taxonRef == taxonRef &&
      other.detected == detected &&
      other.method == method &&
      other.count == count &&
      other.opportunistic == opportunistic;

  @override
  int get hashCode =>
      Object.hash(visitId, taxonRef, detected, method, count, opportunistic);
}

/// The target taxa for which [detections] holds no record — the "not
/// recorded" targets of a Visit (INV-019). A Detection with `detected = false`
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

/// Whether every target taxon has a Detection — the target-completeness factor
/// of analysis-readiness (INV-019, INV-022).
bool allTargetsRecorded(
  List<TargetTaxon> targets,
  List<Detection> detections,
) => unrecordedTargets(targets, detections).isEmpty;

/// Whether every Detection carries a non-blank method. A Detection persisted
/// before the client schema recorded methods has a null one, and the sync API
/// requires a method; a Visit holding such a Detection cannot be delivered as
/// it stands (GLOSSARY.md › Detection method).
bool allDetectionsHaveMethod(List<Detection> detections) => detections.every(
  (detection) =>
      detection.method != null && detection.method!.trim().isNotEmpty,
);
