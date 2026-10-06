/**
 * The `csv` {@link ExportGenerator} for the `exports` module
 * (ARCHITECTURE.md, ADR-0008): it is the format generator #46 registers on the
 * `EXPORT_GENERATORS` seam. Given an Export, it loads that Export's Project's
 * **analysis-ready** Visits (INV-022, via the `visits` module's readiness
 * derivation), their Detections and the target taxa each Visit's Protocol
 * version declares — its Target list, or, in complete-list mode, the taxa in
 * its declared taxonomic scope — builds the detection-history matrix through
 * the injected builder (#311) and serializes it with {@link serializeCsv}. A
 * Visit that is not analysis-ready is excluded, so only analysis-ready Visits
 * enter an export. The resolution Corrections the readiness derivation applies
 * are shared here (INV-021), so a Detection resolved only by a Correction
 * renders under the reference taxon it resolved to while the stored Visit and
 * Detection rows stay exactly as submitted (INV-001).
 *
 * The builder keeps INV-019 and INV-003: a target taxon with a recorded
 * Detection is `1` or `0`, an unrecorded taxon is left blank, and an
 * opportunistic Detection fills no cell. The matrix carries no coordinates, so
 * no coordinate obfuscation is applied here: INV-011's role-based withholding
 * belongs to #50, where a generator that emits geometry adds it.
 */
import { Inject, Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import {
  detection,
  protocolVersion,
  visit,
  type Export,
} from '../db/schema.js';
import {
  loadAnalysisReadyVisitIds,
  loadResolvedTaxaByVisit,
} from '../visits/readiness.js';
import { targetTaxaOf } from '../visits/visit-rules.js';
import { serializeCsv } from './csv.js';
import {
  type DetectionHistoryDetection,
  type DetectionHistoryMatrix,
  type DetectionHistoryVisit,
} from './detection-history.js';
import type { ExportGenerator } from './export.processor.js';

/**
 * Builds a detection-history matrix from its Visits (#311). Injected so a
 * sibling (or a test) can supply its own builder without touching the
 * generator; the default binding is the #311 `buildDetectionHistoryMatrix`.
 */
export type DetectionHistoryBuilder = (
  visits: readonly DetectionHistoryVisit[],
) => DetectionHistoryMatrix;

/** DI token for the detection-history matrix builder the generator uses. */
export const DETECTION_HISTORY_BUILDER = 'DETECTION_HISTORY_BUILDER';

/** A Visit being accumulated from its joined Visit/Detection rows. */
interface VisitAccumulator {
  visitId: string;
  siteId: string;
  surveyPeriodId: string;
  startedAt: Date;
  targetTaxonRefs: readonly string[];
  detections: DetectionHistoryDetection[];
}

@Injectable()
export class DetectionHistoryGenerator implements ExportGenerator {
  readonly format = 'csv';

  constructor(
    @Inject(DATABASE) private readonly db: NodePgDatabase,
    @Inject(DETECTION_HISTORY_BUILDER)
    private readonly buildMatrix: DetectionHistoryBuilder,
  ) {}

  /** The Export's Project's detection-history matrix, serialized to CSV. */
  async generate(record: Export): Promise<Uint8Array> {
    const resolvedTaxaByVisit = await loadResolvedTaxaByVisit(
      this.db,
      record.projectId,
    );
    const readyVisitIds = await loadAnalysisReadyVisitIds(
      this.db,
      record.projectId,
      resolvedTaxaByVisit,
    );
    const visits = await this.loadVisits(
      record.projectId,
      readyVisitIds,
      resolvedTaxaByVisit,
    );
    const matrix = this.buildMatrix(visits);
    const csv = serializeCsv([matrix.header, ...matrix.rows]);
    return new TextEncoder().encode(csv);
  }

  /**
   * Loads a Project's analysis-ready Visits with their Detections and the
   * Protocol version each references, shaped as the builder's input. A Visit
   * the readiness derivation excludes (INV-022) is skipped, so a provisional
   * Visit never reaches the matrix. A Visit with no Detection still yields a
   * row (its cells are blank).
   */
  private async loadVisits(
    projectId: string,
    readyVisitIds: ReadonlySet<string>,
    resolvedTaxaByVisit: ReadonlyMap<string, ReadonlyMap<string, string>>,
  ): Promise<DetectionHistoryVisit[]> {
    const rows = await this.db
      .select({
        visitId: visit.id,
        siteId: visit.siteId,
        surveyPeriodId: visit.surveyPeriodId,
        startedAt: visit.startedAt,
        document: protocolVersion.document,
        detectionTaxon: detection.taxon,
        detectionProvisionalName: detection.provisionalName,
        detectionDetected: detection.detected,
        detectionOpportunistic: detection.opportunistic,
      })
      .from(visit)
      .innerJoin(
        protocolVersion,
        eq(visit.protocolVersionId, protocolVersion.id),
      )
      .leftJoin(detection, eq(detection.visitId, visit.id))
      .where(eq(visit.projectId, projectId));

    const byVisit = new Map<string, VisitAccumulator>();
    for (const row of rows) {
      if (!readyVisitIds.has(row.visitId)) {
        continue;
      }
      let entry = byVisit.get(row.visitId);
      if (entry === undefined) {
        entry = {
          visitId: row.visitId,
          siteId: row.siteId,
          // The Visit resolution columns are nullable under ADR-0021, but the
          // analysis-readiness derivation (INV-020, INV-022) excludes every
          // Visit without a Survey period, so a ready row carries one here.
          surveyPeriodId: row.surveyPeriodId!,
          startedAt: row.startedAt,
          targetTaxonRefs: targetTaxaOf(row.document),
          detections: [],
        };
        byVisit.set(row.visitId, entry);
      }
      // The stored taxon wins (INV-001); a null one is provisional and the
      // resolution fold shared with the readiness derivation supplies the
      // reference taxon it resolved to (INV-021). A ready Visit has no
      // unresolved provisional Detection, so the fold always supplies one.
      const taxon =
        row.detectionTaxon ??
        (row.detectionProvisionalName !== null
          ? resolvedTaxaByVisit
              .get(row.visitId)
              ?.get(row.detectionProvisionalName)
          : undefined);
      if (taxon !== undefined && taxon !== null) {
        entry.detections.push({
          taxon,
          detected: row.detectionDetected ?? false,
          opportunistic: row.detectionOpportunistic ?? false,
        });
      }
    }
    return [...byVisit.values()];
  }
}
