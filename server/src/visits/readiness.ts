/**
 * Derived analysis-readiness for the `visits` module (ARCHITECTURE.md,
 * ADR-0021, INV-019 – INV-022). A Visit is stored as it stands (INV-022) and is
 * never rejected for readiness at ingest, so analysis-readiness is derived from
 * stored state here — the Project's pinned Taxonomic reference (INV-021), the
 * Visit's Survey period and Protocol version (INV-020), its required Sampling
 * effort (INV-005), every Target list taxon recorded (INV-019), and no
 * provisional Detection (INV-021). A Visit that fails any factor is provisional
 * and excluded from every export (INV-022).
 *
 * A synced Visit's provisional taxa are resolved by an append-only Correction
 * (INV-021); this derivation applies the recorded resolution Corrections to the
 * stored state, so a resolved Visit becomes analysis-ready while the stored
 * Visit and Detection rows stay exactly as submitted (INV-001).
 */
import { BadRequestException } from '@nestjs/common';
import { asc, eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import {
  correction,
  detection,
  project,
  protocolVersion,
  visit,
} from '../db/schema.js';
import {
  missingRequiredEffortFields,
  missingTargetTaxa,
  requiredEffortFieldsOf,
  targetTaxaOf,
  type DetectionTaxon,
} from './visit-rules.js';

/** The discriminator a resolution Correction's payload carries (INV-021). */
export const RESOLUTION_CORRECTION_KIND = 'resolution';

/** One provisional taxon resolved to a reference taxon (INV-021). */
export interface ResolutionTaxonAssignment {
  /** The provisional taxon as stored on the Detection (GLOSSARY.md). */
  provisionalName: string;
  /** The reference taxon it resolves to (INV-021). */
  taxon: string;
}

/**
 * A resolution Correction's typed payload (INV-021): the provisional taxa
 * resolved to reference taxa and the pinned Taxonomic reference version they
 * resolved against, stored with the data it resolved. A Correction carrying
 * this payload never mutates the submitted Visit (INV-001); the derived views
 * apply it.
 */
export interface ResolutionCorrectionPayload {
  kind: typeof RESOLUTION_CORRECTION_KIND;
  taxonomicReferenceVersion: string;
  resolvedTaxa: ResolutionTaxonAssignment[];
}

/** Whether `value` is a well-formed resolution Correction payload (INV-021). */
export function isResolutionCorrectionPayload(
  value: unknown,
): value is ResolutionCorrectionPayload {
  if (typeof value !== 'object' || value === null) {
    return false;
  }
  const payload = value as Record<string, unknown>;
  if (payload.kind !== RESOLUTION_CORRECTION_KIND) {
    return false;
  }
  if (
    typeof payload.taxonomicReferenceVersion !== 'string' ||
    payload.taxonomicReferenceVersion.length === 0
  ) {
    return false;
  }
  if (
    !Array.isArray(payload.resolvedTaxa) ||
    payload.resolvedTaxa.length === 0
  ) {
    return false;
  }
  return payload.resolvedTaxa.every((entry) => {
    if (typeof entry !== 'object' || entry === null) {
      return false;
    }
    const assignment = entry as Record<string, unknown>;
    return (
      typeof assignment.provisionalName === 'string' &&
      assignment.provisionalName.length > 0 &&
      typeof assignment.taxon === 'string' &&
      assignment.taxon.length > 0
    );
  });
}

/**
 * Rejects a Correction whose payload claims to be a resolution but is
 * malformed (INV-021). A payload that is not a resolution is left opaque, so
 * every other Correction is unaffected.
 */
export function assertResolutionCorrectionPayload(
  payload: Record<string, unknown>,
): void {
  if (payload.kind !== RESOLUTION_CORRECTION_KIND) {
    return;
  }
  if (!isResolutionCorrectionPayload(payload)) {
    throw new BadRequestException(
      'a resolution Correction must carry a non-empty reference version and at least one resolved taxon',
    );
  }
}

/** One Detection's stored state as readiness needs it (INV-021). */
export interface StoredDetection {
  /** The resolved taxon, or null when the Detection is provisional (INV-021). */
  taxon: string | null;
  /**
   * The provisional taxon, or null when the Detection is already resolved
   * (INV-021).
   */
  provisionalName: string | null;
  /** True when the Detection is outside the Target list (INV-003). */
  opportunistic: boolean;
}

/** The stored state one Visit's analysis-readiness is derived from. */
export interface AnalysisReadinessInput {
  /** Whether the Visit's Project has a pinned Taxonomic reference (INV-021). */
  hasPinnedReference: boolean;
  /** The Visit's Survey period id, null until attached (INV-020). */
  surveyPeriodId: string | null;
  /** The Visit's Protocol version id, null until attached (INV-020). */
  protocolVersionId: string | null;
  /** The Visit's recorded Sampling effort (INV-005). */
  effort: Record<string, unknown>;
  /** The referenced Protocol version document, null when none is attached. */
  protocolDocument: Record<string, unknown> | null;
  /** The Visit's Detections (INV-019, INV-021). */
  detections: readonly StoredDetection[];
  /**
   * The taxon each provisional Detection is resolved to by a recorded
   * resolution Correction (INV-021), empty when none are applied.
   */
  resolvedTaxa?: ReadonlyMap<string, string>;
}

/**
 * Whether a Visit with `input` is analysis-ready (INV-019 – INV-022): it has
 * the Project's pinned reference, exactly one Survey period and Protocol
 * version, its required effort recorded (INV-005), every Target list taxon
 * recorded (INV-019), and no provisional Detection (INV-021).
 */
export function isAnalysisReady(input: AnalysisReadinessInput): boolean {
  if (!input.hasPinnedReference) {
    return false;
  }
  if (input.surveyPeriodId === null) {
    return false;
  }
  if (input.protocolVersionId === null || input.protocolDocument === null) {
    return false;
  }

  const document = input.protocolDocument;
  const resolvedTaxa = input.resolvedTaxa ?? new Map<string, string>();
  const resolvedDetections: DetectionTaxon[] = [];
  for (const stored of input.detections) {
    const taxon =
      stored.taxon ??
      (stored.provisionalName !== null
        ? resolvedTaxa.get(stored.provisionalName)
        : undefined);
    if (taxon === undefined || taxon === null) {
      return false;
    }
    resolvedDetections.push({
      taxon,
      opportunistic: stored.opportunistic,
    });
  }

  if (
    missingRequiredEffortFields(input.effort, requiredEffortFieldsOf(document))
      .length > 0
  ) {
    return false;
  }
  if (
    missingTargetTaxa(resolvedDetections, targetTaxaOf(document)).length > 0
  ) {
    return false;
  }
  return true;
}

/** A Visit accumulated from its joined Visit/Protocol version/Detection rows. */
interface VisitAccumulator {
  surveyPeriodId: string | null;
  protocolVersionId: string | null;
  effort: Record<string, unknown>;
  protocolDocument: Record<string, unknown> | null;
  detections: StoredDetection[];
}

/**
 * The ids of `projectId`'s analysis-ready Visits (INV-019 – INV-022), derived
 * from stored state. A Visit with no Detection still yields an accumulator, so
 * a Target list it does not satisfy leaves it out.
 */
export async function loadAnalysisReadyVisitIds(
  db: NodePgDatabase,
  projectId: string,
): Promise<Set<string>> {
  const [owner] = await db
    .select({
      taxonomicReferenceId: project.taxonomicReferenceId,
      taxonomicReferenceVersion: project.taxonomicReferenceVersion,
    })
    .from(project)
    .where(eq(project.id, projectId))
    .limit(1);

  const hasPinnedReference =
    owner !== undefined &&
    owner.taxonomicReferenceId !== null &&
    owner.taxonomicReferenceVersion !== null;

  // The recorded resolution Corrections (INV-021) applied in recorded order, so
  // a later assignment for the same provisional taxon wins. The stored Visit
  // and Detection rows are never read back mutated — the derived view applies
  // the Corrections (INV-001).
  const correctionRows = await db
    .select({ visitId: correction.visitId, payload: correction.payload })
    .from(correction)
    .innerJoin(visit, eq(correction.visitId, visit.id))
    .where(eq(visit.projectId, projectId))
    .orderBy(asc(correction.createdAt));

  const resolvedTaxaByVisit = new Map<string, Map<string, string>>();
  for (const row of correctionRows) {
    if (!isResolutionCorrectionPayload(row.payload)) {
      continue;
    }
    const resolved = resolvedTaxaByVisit.get(row.visitId) ?? new Map();
    for (const assignment of row.payload.resolvedTaxa) {
      resolved.set(assignment.provisionalName, assignment.taxon);
    }
    resolvedTaxaByVisit.set(row.visitId, resolved);
  }

  const rows = await db
    .select({
      visitId: visit.id,
      surveyPeriodId: visit.surveyPeriodId,
      protocolVersionId: visit.protocolVersionId,
      effort: visit.effort,
      protocolDocument: protocolVersion.document,
      detectionId: detection.id,
      detectionTaxon: detection.taxon,
      detectionProvisionalName: detection.provisionalName,
      detectionOpportunistic: detection.opportunistic,
    })
    .from(visit)
    .leftJoin(protocolVersion, eq(visit.protocolVersionId, protocolVersion.id))
    .leftJoin(detection, eq(detection.visitId, visit.id))
    .where(eq(visit.projectId, projectId));

  const byVisit = new Map<string, VisitAccumulator>();
  for (const row of rows) {
    let entry = byVisit.get(row.visitId);
    if (entry === undefined) {
      entry = {
        surveyPeriodId: row.surveyPeriodId,
        protocolVersionId: row.protocolVersionId,
        effort: row.effort,
        protocolDocument: row.protocolDocument,
        detections: [],
      };
      byVisit.set(row.visitId, entry);
    }
    if (row.detectionId !== null) {
      entry.detections.push({
        taxon: row.detectionTaxon,
        provisionalName: row.detectionProvisionalName,
        opportunistic: row.detectionOpportunistic ?? false,
      });
    }
  }

  const ready = new Set<string>();
  for (const [visitId, accumulator] of byVisit) {
    if (
      isAnalysisReady({
        hasPinnedReference,
        surveyPeriodId: accumulator.surveyPeriodId,
        protocolVersionId: accumulator.protocolVersionId,
        effort: accumulator.effort,
        protocolDocument: accumulator.protocolDocument,
        detections: accumulator.detections,
        resolvedTaxa: resolvedTaxaByVisit.get(visitId),
      })
    ) {
      ready.add(visitId);
    }
  }
  return ready;
}
