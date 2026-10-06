/**
 * Protocol-level readiness predicates for the `visits` module (DOMAIN.md,
 * ARCHITECTURE.md). A predicate is a pure function over a submission's data and
 * the Protocol version document it references. A Visit is stored as it stands
 * (ADR-0021, INV-022) and is never rejected for readiness at ingest, so these
 * feed the derived analysis-readiness (INV-019 – INV-022) rather than
 * submission-time guards. The one structural rule the ingest still enforces is
 * a Detection's taxon shape (INV-021).
 */
import { BadRequestException } from '@nestjs/common';

/**
 * The Sampling-effort field names a Protocol version's document requires, read
 * from its `requiredEffortFields` (packages/protocol `SamplingEffortField`). A
 * document that omits the list requires no Sampling-effort field.
 */
export function requiredEffortFieldsOf(
  document: Record<string, unknown>,
): string[] {
  const value = document.requiredEffortFields;
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((entry): entry is string => typeof entry === 'string');
}

/** The required Sampling-effort fields `effort` does not record a value for. */
export function missingRequiredEffortFields(
  effort: Record<string, unknown>,
  requiredEffortFields: readonly string[],
): string[] {
  return requiredEffortFields.filter((field) => {
    const value = effort[field];
    return value === undefined || value === null;
  });
}

/**
 * The taxon identifiers a Protocol version's declared taxonomic scope lists,
 * read from its `taxonomicScope.taxa` (packages/protocol `TaxonomicScope`). In
 * complete-list mode these are the required target taxa (INV-004,
 * GLOSSARY.md Target list). A document that omits the scope, or carries
 * non-string entries, contributes none.
 */
function scopeTaxaOf(document: Record<string, unknown>): string[] {
  const scope = document.taxonomicScope;
  if (typeof scope !== 'object' || scope === null) {
    return [];
  }
  const taxa = (scope as { taxa?: unknown }).taxa;
  if (!Array.isArray(taxa)) {
    return [];
  }
  return taxa.filter((entry): entry is string => typeof entry === 'string');
}

/**
 * The taxon identifiers a Protocol version requires a Detection for (INV-004,
 * GLOSSARY.md Target list). A document with a `targetList`
 * (packages/protocol `TargetTaxon`) uses it. A document that omits the list is
 * in complete-list mode, where the declared taxonomic scope — its
 * `taxonomicScope.taxa` — defines the required taxa.
 */
export function targetTaxaOf(document: Record<string, unknown>): string[] {
  const value = document.targetList;
  if (!Array.isArray(value)) {
    return scopeTaxaOf(document);
  }
  const taxa: string[] = [];
  for (const entry of value) {
    if (
      typeof entry === 'object' &&
      entry !== null &&
      'taxonRef' in entry &&
      typeof (entry as { taxonRef?: unknown }).taxonRef === 'string'
    ) {
      taxa.push((entry as { taxonRef: string }).taxonRef);
    }
  }
  return taxa;
}

/** A Detection's taxon and whether it is opportunistic (DOMAIN.md, INV-003). */
export interface DetectionTaxon {
  taxon: string;
  opportunistic?: boolean;
}

/**
 * The target taxa `detections` records no satisfying Detection for. A
 * non-opportunistic Detection satisfies its taxon whether `detected` is true or
 * false — a non-detection is a recorded state, not a missing record (glossary
 * Non-detection); an opportunistic Detection never satisfies a target (INV-003).
 */
export function missingTargetTaxa(
  detections: readonly DetectionTaxon[],
  targetTaxa: readonly string[],
): string[] {
  const recorded = new Set(
    detections
      .filter((detection) => detection.opportunistic !== true)
      .map((detection) => detection.taxon),
  );
  return targetTaxa.filter((taxon) => !recorded.has(taxon));
}

/**
 * Rejects a Detection that does not carry exactly one of a resolved `taxon` or
 * a provisional name, or that carries a provisional name while not recording a
 * presence (INV-021). A provisional taxon is unresolved, so it is presence-only
 * — it cannot be claimed as searched-for-and-not-detected. This is a structural
 * rule, not readiness: it runs before the ingest transaction, so a malformed
 * Detection stores no Visit.
 */
export function assertDetectionTaxonShape(detection: {
  taxon?: string | null;
  provisionalName?: string | null;
  detected: boolean;
}): void {
  const hasTaxon = detection.taxon !== undefined && detection.taxon !== null;
  const hasProvisionalName =
    detection.provisionalName !== undefined &&
    detection.provisionalName !== null;
  if (hasTaxon === hasProvisionalName) {
    throw new BadRequestException(
      'a Detection must carry either a resolved taxon or a provisional name, not both and not neither',
    );
  }
  if (hasProvisionalName && detection.detected !== true) {
    throw new BadRequestException(
      'a provisional Detection is presence-only and must record detected = true',
    );
  }
}

/**
 * Rejects a submission that carries a Detection with a resolved `taxon` while
 * the Project has no pinned Taxonomic reference (INV-021): a resolved taxon's
 * reference version is stored with the data it resolved against, so resolution
 * without a pin is impossible. A provisional Detection is unaffected — it is
 * accepted with no pin. Runs inside the ingest transaction, so throwing here
 * stores no Visit.
 */
export function assertResolvedDetectionsHaveReference(
  detections: readonly { taxon?: string | null }[],
  hasPinnedReference: boolean,
): void {
  if (hasPinnedReference) {
    return;
  }
  if (detections.some((detection) => detection.taxon != null)) {
    throw new BadRequestException(
      'a resolved Detection requires the Project to have a pinned Taxonomic reference',
    );
  }
}
