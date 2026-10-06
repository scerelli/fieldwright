import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocol/protocol.dart';
import '../../store/database_provider.dart';
import '../../store/detection_dao.dart';
import 'detection.dart';
import 'visit.dart';

/// One condition of analysis-readiness a Visit does not yet meet (INV-022,
/// UX-035). Each is named in the needs-attention surface with the action that
/// clears it; none blocks capture, ending or submission.
enum ReadinessRequirement {
  /// The Visit has no Protocol version attached (INV-020).
  protocolVersion,

  /// The Visit has no Survey period attached (INV-020).
  surveyPeriod,

  /// The Visit's Project has no pinned Taxonomic reference (INV-021).
  pinnedReference,

  /// A target taxon of the Visit's Protocol version has no Detection (INV-019).
  unrecordedTargets,

  /// A Detection's taxon is provisional, not yet resolved (INV-021).
  unresolvedTaxa,
}

/// The derived analysis-readiness of a Visit (`GLOSSARY.md` › Analysis-ready,
/// INV-022): the requirements it does not yet meet, and the counts the
/// needs-attention surface names. A Visit with an empty [unmet] is
/// analysis-ready and fit for export; one with any is **provisional**.
class VisitReadiness {
  const VisitReadiness({
    this.unmet = const <ReadinessRequirement>[],
    this.projectId,
    this.unrecordedTargetCount = 0,
    this.provisionalTaxonCount = 0,
  });

  /// The requirements the Visit does not yet meet, in the order the surface
  /// names them.
  final List<ReadinessRequirement> unmet;

  /// The id of the Visit's Project, when it is known, so an action can open
  /// that Project's configuration surface.
  final String? projectId;

  /// How many target taxa have no Detection (INV-019).
  final int unrecordedTargetCount;

  /// How many Detections hold a provisional taxon (INV-021).
  final int provisionalTaxonCount;

  bool get isAnalysisReady => unmet.isEmpty;
}

/// The target taxa a Protocol version requires a Detection for (INV-004,
/// GLOSSARY.md › Target list). A document with a Target list uses it; a
/// document that omits it is in complete-list mode, where the declared
/// Taxonomic scope — `taxonomicScope.taxa` — defines the required taxa.
List<TargetTaxon> requiredTargetTaxa(ProtocolDocument document) =>
    document.targetList ??
    <TargetTaxon>[
      for (final taxonRef in document.taxonomicScope.taxa)
        TargetTaxon(taxonRef: taxonRef),
    ];

/// Derives whether [visit] is analysis-ready from its stored state plus applied
/// Corrections (`ARCHITECTURE.md`, ADR-0021): exactly one Survey period and one
/// Protocol version, its Project's pinned Taxonomic reference, every target
/// taxon recorded, and no provisional Detection.
VisitReadiness deriveVisitReadiness({
  required Visit visit,
  required List<Detection> detections,
  required List<TargetTaxon> targets,
  required bool hasPinnedReference,
  String? projectId,
}) {
  final unrecorded = unrecordedTargets(targets, detections);
  final provisional = provisionalTaxa(
    detections,
    hasPinnedReference: hasPinnedReference,
  );
  final unmet = <ReadinessRequirement>[
    if (visit.protocolVersionId == null) ReadinessRequirement.protocolVersion,
    if (visit.surveyPeriodId == null) ReadinessRequirement.surveyPeriod,
    if (!hasPinnedReference) ReadinessRequirement.pinnedReference,
    if (unrecorded.isNotEmpty) ReadinessRequirement.unrecordedTargets,
    if (provisional.isNotEmpty) ReadinessRequirement.unresolvedTaxa,
  ];
  return VisitReadiness(
    unmet: unmet,
    projectId: projectId,
    unrecordedTargetCount: unrecorded.length,
    provisionalTaxonCount: provisional.length,
  );
}

/// The taxon keys of [detections] that are provisional — not resolved against
/// the Project's pinned Taxonomic reference (GLOSSARY.md › Provisional taxon).
///
/// On the client, provisional status is derived, never stored
/// (`ARCHITECTURE.md` client local store): a Detection is provisional when the
/// Project has no pinned reference, or its stored taxon key does not resolve
/// against the pinned cache. Until the pinned reference artifact is wired into
/// the client store, only the first half is reachable — with no pin, every
/// Detection is provisional and presence-only (INV-021); with a pin, the stored
/// keys are trusted as resolved.
Set<String> provisionalTaxa(
  Iterable<Detection> detections, {
  required bool hasPinnedReference,
}) {
  if (hasPinnedReference) return const <String>{};
  return <String>{for (final detection in detections) detection.taxonRef};
}

/// Derives [visitId]'s analysis-readiness from the local store: its stored
/// state, its Project's pinned reference and its Protocol version's required
/// target taxa (its Target list, or the declared Taxonomic scope in
/// complete-list mode), and its Detections (`ARCHITECTURE.md`, ADR-0021). The
/// needs-attention surface watches this; submission never does.
final visitReadinessProvider = FutureProvider.family<VisitReadiness, String>((
  ref,
  visitId,
) async {
  final visit = await ref.watch(visitDaoProvider).findById(visitId);
  if (visit == null) return const VisitReadiness();
  final site = await ref.watch(siteDaoProvider).findById(visit.siteId);
  final config = ref.watch(configDaoProvider);
  final project = site == null ? null : await config.project(site.projectId);
  final detections = await ref.watch(detectionDaoProvider).forVisit(visitId);
  final protocolVersionId = visit.protocolVersionId;
  final protocolVersion = protocolVersionId == null
      ? null
      : await config.protocolVersion(protocolVersionId);
  final targets = protocolVersion == null
      ? const <TargetTaxon>[]
      : requiredTargetTaxa(protocolVersion.document);
  return deriveVisitReadiness(
    visit: visit,
    detections: detections,
    targets: targets,
    hasPinnedReference: project?.taxonomicReferenceId != null,
    projectId: project?.id,
  );
});
