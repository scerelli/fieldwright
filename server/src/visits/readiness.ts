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
 * Appending the Corrections that resolve a synced Visit's provisional taxa
 * (INV-021) into this derivation is Story #393's sibling #401; this file reads
 * the stored state as it stands.
 */
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { detection, project, protocolVersion, visit } from '../db/schema.js';
import {
  missingRequiredEffortFields,
  missingTargetTaxa,
  requiredEffortFieldsOf,
  targetTaxaOf,
  type DetectionTaxon,
} from './visit-rules.js';

/** One Detection's stored state as readiness needs it (INV-021). */
export interface StoredDetection {
  /** The resolved taxon, or null when the Detection is provisional (INV-021). */
  taxon: string | null;
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
  const resolvedDetections: DetectionTaxon[] = [];
  for (const stored of input.detections) {
    if (stored.taxon === null) {
      return false;
    }
    resolvedDetections.push({
      taxon: stored.taxon,
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

  const rows = await db
    .select({
      visitId: visit.id,
      surveyPeriodId: visit.surveyPeriodId,
      protocolVersionId: visit.protocolVersionId,
      effort: visit.effort,
      protocolDocument: protocolVersion.document,
      detectionId: detection.id,
      detectionTaxon: detection.taxon,
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
      })
    ) {
      ready.add(visitId);
    }
  }
  return ready;
}
