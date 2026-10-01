/**
 * Protocol-level submission rules for the `visits` module (DOMAIN.md,
 * ARCHITECTURE.md). A rule is a pure predicate over a submission's data and
 * the Protocol version document it references; the ingest transaction in
 * `visits.service.ts` loads that document and runs these before storing, so a
 * rejected submission leaves no Visit behind (ADR-0010: rule-heavy rules run
 * in server code inside a transaction).
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
 * The taxon identifiers a Protocol version's Target list requires a Detection
 * for, read from its `targetList` (packages/protocol `TargetTaxon`). A document
 * that omits the list is in complete-list mode, where the declared taxonomic
 * scope — not a Target list — defines the required taxa, so it requires none
 * here.
 */
export function targetTaxaOf(document: Record<string, unknown>): string[] {
  const value = document.targetList;
  if (!Array.isArray(value)) {
    return [];
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
 * Rejects a submission that omits a Detection for a taxon its Protocol
 * version's Target list names (INV-002). Runs inside the ingest transaction, so
 * throwing here stores no Visit.
 */
export function assertTargetTaxonCompleteness(
  detections: readonly DetectionTaxon[],
  targetTaxa: readonly string[],
): void {
  const missing = missingTargetTaxa(detections, targetTaxa);
  if (missing.length > 0) {
    throw new BadRequestException(
      `Visit is missing a Detection for target taxon(s): ${missing.join(', ')}`,
    );
  }
}

/**
 * Rejects a submission whose Sampling effort omits a field its Protocol
 * version requires (INV-005). Runs inside the ingest transaction, so throwing
 * here stores no Visit.
 */
export function assertRequiredEffortFields(
  effort: Record<string, unknown>,
  requiredEffortFields: readonly string[],
): void {
  const missing = missingRequiredEffortFields(effort, requiredEffortFields);
  if (missing.length > 0) {
    throw new BadRequestException(
      `Sampling effort is missing required field(s): ${missing.join(', ')}`,
    );
  }
}
