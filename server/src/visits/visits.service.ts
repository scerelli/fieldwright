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
 * Protocol-level rules — target-taxon completeness (INV-002), complete-list
 * scope (INV-004), required Sampling effort fields (INV-005) and taxon
 * resolution against the pinned Taxonomic reference (INV-008) — are enforced
 * by the submission use case that calls this store, which holds the Protocol
 * version document; this service is the storage primitive beneath it.
 */
import { Inject, Injectable } from '@nestjs/common';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import {
  detection,
  evidence,
  measurement,
  visit,
  type MeasurementProvenance,
  type Visit,
} from '../db/schema.js';

export interface StoreDetectionInput {
  taxon: string;
  detected: boolean;
  method: string;
  count?: number | null;
  opportunistic?: boolean;
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

@Injectable()
export class VisitsService {
  constructor(@Inject(DATABASE) private readonly db: NodePgDatabase) {}

  /**
   * Stores a submitted Visit with its parts in one transaction. Detections are
   * inserted first so a Detection-level Measurement or Evidence can reference
   * one by its position in the input via `detectionIndex`.
   */
  async storeSubmittedVisit(input: StoreSubmittedVisitInput): Promise<Visit> {
    return this.db.transaction(async (tx) => {
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
      const detections = input.detections ?? [];
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

      const ownerDetectionId = (index?: number | null): string | null =>
        index === undefined || index === null
          ? null
          : (detectionIds[index] ?? null);

      const measurements = input.measurements ?? [];
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

      const evidenceRows = input.evidence ?? [];
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
