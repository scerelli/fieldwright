/**
 * The server `visits` module's persistence (ARCHITECTURE.md, DOMAIN.md). A
 * submitted Visit is immutable (INV-001); this service stores one whole
 * aggregate — the Visit, its Detections, Measurements and Evidence — in a
 * single transaction, so a failure leaves no partial record. There is no
 * update path: a later change to a submitted Visit is a Correction.
 *
 * The Visit must reference a Site, a Survey period and a Protocol version
 * (INV-006); the non-null foreign keys reject a reference to a missing row,
 * and an invalid part (a negative count, a Measurement without a method)
 * aborts the whole submission.
 *
 * Protocol-level rules are enforced in this ingest transaction, which loads
 * the Visit's referenced Protocol version document: required Sampling-effort
 * fields (INV-005) today. Target-taxon completeness (INV-002), complete-list
 * scope (INV-004) and taxon resolution against the pinned Taxonomic reference
 * (INV-008) belong here too and are added as their own rules.
 */
import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import {
  detection,
  determination,
  evidence,
  measurement,
  protocolVersion,
  visit,
  type MeasurementProvenance,
  type Visit,
} from '../db/schema.js';
import {
  assertRequiredEffortFields,
  assertTargetTaxonCompleteness,
  requiredEffortFieldsOf,
  targetTaxaOf,
} from './visit-rules.js';

export interface StoreDeterminationInput {
  taxon: string;
  qualifier?: 'cf.' | 'aff.' | 'sp.' | null;
  specimenCode?: string | null;
  determiner: string;
  date: string;
  replacesIndex?: number | null;
}

export interface StoreDetectionInput {
  taxon: string;
  detected: boolean;
  method: string;
  count?: number | null;
  opportunistic?: boolean;
  determinations?: StoreDeterminationInput[];
}

export interface StoreMeasurementInput {
  detectionIndex?: number | null;
  value: string;
  unit: string;
  provenance: MeasurementProvenance;
}

export interface StoreEvidenceInput {
  detectionIndex?: number | null;
  kind: 'photo' | 'audio';
  storageKey: string;
  sha256: string;
}

export interface StoreSubmittedVisitInput {
  id: string;
  projectId: string;
  siteId: string;
  surveyPeriodId: string;
  protocolVersionId: string;
  effort: Record<string, unknown>;
  startedAt: Date;
  endedAt?: Date | null;
  submittedAt: Date;
  detections?: StoreDetectionInput[];
  measurements?: StoreMeasurementInput[];
  evidence?: StoreEvidenceInput[];
}

function assertDetectionIndicesInRange(
  entries: ReadonlyArray<{ detectionIndex?: number | null }>,
  detectionsCount: number,
  part: 'Measurement' | 'Evidence',
): void {
  for (const entry of entries) {
    const index = entry.detectionIndex;
    if (index === undefined || index === null) {
      continue;
    }
    if (index < 0 || index >= detectionsCount) {
      throw new BadRequestException(
        `${part} detectionIndex ${index} does not refer to a Detection in the submission`,
      );
    }
  }
}

@Injectable()
export class VisitsService {
  constructor(@Inject(DATABASE) private readonly db: NodePgDatabase) {}

  /**
   * Stores a submitted Visit with its parts in one transaction. Detections are
   * inserted first so a Detection-level Measurement or Evidence can reference
   * one by its position in the input via `detectionIndex`. A provided
   * `detectionIndex` that names no Detection in the submission is rejected, so a
   * Measurement or Evidence is never silently stored at the Visit level.
   */
  async storeSubmittedVisit(input: StoreSubmittedVisitInput): Promise<Visit> {
    const detections = input.detections ?? [];
    const measurements = input.measurements ?? [];
    const evidenceRows = input.evidence ?? [];

    assertDetectionIndicesInRange(
      measurements,
      detections.length,
      'Measurement',
    );
    assertDetectionIndicesInRange(evidenceRows, detections.length, 'Evidence');

    return this.db.transaction(async (tx) => {
      const [version] = await tx
        .select({ document: protocolVersion.document })
        .from(protocolVersion)
        .where(eq(protocolVersion.id, input.protocolVersionId))
        .limit(1);
      if (version === undefined) {
        throw new BadRequestException(
          `Protocol version ${input.protocolVersionId} does not exist`,
        );
      }
      assertRequiredEffortFields(
        input.effort,
        requiredEffortFieldsOf(version.document),
      );
      assertTargetTaxonCompleteness(
        detections,
        targetTaxaOf(version.document),
      );

      const [created] = await tx
        .insert(visit)
        .values({
          id: input.id,
          projectId: input.projectId,
          siteId: input.siteId,
          surveyPeriodId: input.surveyPeriodId,
          protocolVersionId: input.protocolVersionId,
          state: 'submitted',
          effort: input.effort,
          startedAt: input.startedAt,
          endedAt: input.endedAt ?? null,
          submittedAt: input.submittedAt,
        })
        .returning();

      const detectionIds: string[] = [];
      if (detections.length > 0) {
        const rows = await tx
          .insert(detection)
          .values(
            detections.map((entry) => ({
              visitId: created.id,
              taxon: entry.taxon,
              detected: entry.detected,
              method: entry.method,
              count: entry.count ?? null,
              opportunistic: entry.opportunistic ?? false,
            })),
          )
          .returning({ id: detection.id });
        detectionIds.push(...rows.map((row) => row.id));
      }

      for (let i = 0; i < detections.length; i += 1) {
        const entries = detections[i]!.determinations ?? [];
        const determinationIds: string[] = [];
        for (const entry of entries) {
          const replacesIndex = entry.replacesIndex ?? null;
          const replacesId =
            replacesIndex === null
              ? null
              : (determinationIds[replacesIndex] ?? null);
          if (replacesIndex !== null && replacesId === null) {
            throw new BadRequestException(
              `Determination replacesIndex ${replacesIndex} does not refer to a stored Determination`,
            );
          }
          const [row] = await tx
            .insert(determination)
            .values({
              detectionId: detectionIds[i]!,
              taxon: entry.taxon,
              qualifier: entry.qualifier ?? null,
              specimenCode: entry.specimenCode ?? null,
              determiner: entry.determiner,
              date: entry.date,
              replacesId,
            })
            .returning({ id: determination.id });
          determinationIds.push(row!.id);
        }
      }

      const ownerDetectionId = (index?: number | null): string | null =>
        index === undefined || index === null
          ? null
          : (detectionIds[index] ?? null);

      if (measurements.length > 0) {
        await tx.insert(measurement).values(
          measurements.map((entry) => ({
            visitId: created.id,
            detectionId: ownerDetectionId(entry.detectionIndex),
            value: entry.value,
            unit: entry.unit,
            provenance: entry.provenance,
          })),
        );
      }

      if (evidenceRows.length > 0) {
        await tx.insert(evidence).values(
          evidenceRows.map((entry) => ({
            visitId: created.id,
            detectionId: ownerDetectionId(entry.detectionIndex),
            kind: entry.kind,
            storageKey: entry.storageKey,
            sha256: entry.sha256,
          })),
        );
      }

      return created;
    });
  }
}
