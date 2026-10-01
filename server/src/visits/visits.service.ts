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
 * fields (INV-005) today. Target-taxon completeness (INV-002) and complete-list
 * scope (INV-004) belong here too and are added as their own rules.
 *
 * The transaction also copies the Project's pinned Taxonomic reference id and
 * version onto the Visit (INV-008), so the reference the data was captured
 * against is stored with the data; the NOT NULL columns reject a row stored
 * without it. Resolving taxon names against that reference is the other half of
 * INV-008 and is deferred until the reference lists and their versioning are
 * decided (DOMAIN.md Open questions).
 */
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { and, asc, eq, inArray } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import {
  correction,
  detection,
  determination,
  evidence,
  measurement,
  membership,
  project,
  protocolVersion,
  visit,
  type Correction,
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

export interface RecordCorrectionInput {
  reason: string;
  payload: Record<string, unknown>;
}

/**
 * A stored Visit's Validation state as read through the versioned API
 * (GLOSSARY.md Validation, INV-013): its lifecycle `state`, the validating
 * Person's id and the Validation instant, both null until a Validation is
 * recorded.
 */
export interface VisitValidationState {
  state: Visit['state'];
  validatorId: string | null;
  validatedAt: Date | null;
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

      const [owner] = await tx
        .select({
          taxonomicReferenceId: project.taxonomicReferenceId,
          taxonomicReferenceVersion: project.taxonomicReferenceVersion,
        })
        .from(project)
        .where(eq(project.id, input.projectId))
        .limit(1);
      if (owner === undefined) {
        throw new BadRequestException(
          `Project ${input.projectId} does not exist`,
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
          taxonomicReferenceId: owner.taxonomicReferenceId,
          taxonomicReferenceVersion: owner.taxonomicReferenceVersion,
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

  /**
   * Records a Validation: marks a `submitted` Visit `validated` or `rejected`,
   * writing only `state`, `validator_id` and `validated_at` and leaving every
   * other column as submitted (INV-001, INV-013). The project must have
   * validation enabled and the person must hold the `validator` Membership in
   * the Visit's Project; the Visit must be `submitted`. The row is locked for
   * update so two concurrent Validation requests cannot both pass the
   * app-level state check; the database trigger from #269 is the safety net.
   */
  async applyValidation(
    personId: string,
    visitId: string,
    state: 'validated' | 'rejected',
  ): Promise<Visit> {
    return this.db.transaction(async (tx) => {
      const [current] = await tx
        .select()
        .from(visit)
        .where(eq(visit.id, visitId))
        .limit(1)
        .for('update');
      if (current === undefined) {
        throw new NotFoundException(`Visit ${visitId} does not exist`);
      }

      const [validator] = await tx
        .select({ id: membership.id })
        .from(membership)
        .where(
          and(
            eq(membership.personId, personId),
            eq(membership.projectId, current.projectId),
            eq(membership.role, 'validator'),
          ),
        )
        .limit(1);
      if (validator === undefined) {
        throw new ForbiddenException(
          'only a validator may mark a Visit validated or rejected',
        );
      }

      const [owner] = await tx
        .select({ settings: project.settings })
        .from(project)
        .where(eq(project.id, current.projectId))
        .limit(1);
      if (owner === undefined) {
        throw new NotFoundException(
          `Project ${current.projectId} does not exist`,
        );
      }
      if (!owner.settings.validationEnabled) {
        throw new ConflictException(
          'Validation is not enabled for this Project',
        );
      }
      if (current.state !== 'submitted') {
        throw new ConflictException(
          'Validation applies only to a submitted Visit',
        );
      }

      const [updated] = await tx
        .update(visit)
        .set({ state, validatorId: personId, validatedAt: new Date() })
        .where(eq(visit.id, visitId))
        .returning();
      return updated!;
    });
  }

  /**
   * Records a Correction against a stored Visit (GLOSSARY.md Correction,
   * INV-001): one append-only `correction` row carrying the author, the
   * recording time, the reason and the change payload. The submitted Visit is
   * never mutated, so every one of its columns is left exactly as submitted.
   * The person must hold the `collector` or `validator` Membership in the
   * Visit's Project; a Visit that does not exist is refused, and a Visit in
   * `in_progress` or `ended` is not yet stored and is refused, so a refusal
   * stores no row. The Visit row is locked so the existence and state checks
   * stay consistent with a concurrent submission.
   */
  async recordCorrection(
    personId: string,
    visitId: string,
    input: RecordCorrectionInput,
  ): Promise<Correction> {
    return this.db.transaction(async (tx) => {
      const [current] = await tx
        .select()
        .from(visit)
        .where(eq(visit.id, visitId))
        .limit(1)
        .for('update');
      if (current === undefined) {
        throw new NotFoundException(`Visit ${visitId} does not exist`);
      }

      const [member] = await tx
        .select({ id: membership.id })
        .from(membership)
        .where(
          and(
            eq(membership.personId, personId),
            eq(membership.projectId, current.projectId),
            inArray(membership.role, ['collector', 'validator']),
          ),
        )
        .limit(1);
      if (member === undefined) {
        throw new ForbiddenException(
          'only a collector or validator may record a Correction',
        );
      }

      if (current.state === 'in_progress' || current.state === 'ended') {
        throw new ConflictException(
          'a Correction applies only to a stored Visit',
        );
      }

      const [created] = await tx
        .insert(correction)
        .values({
          visitId,
          authorId: personId,
          reason: input.reason,
          payload: input.payload,
        })
        .returning();
      return created!;
    });
  }

  /**
   * Lists a stored Visit's Corrections (GLOSSARY.md Correction, INV-001) in
   * recorded order, oldest first, each carrying its `authorId`, `createdAt`,
   * `reason` and `payload`. The Visit must exist — a missing id is refused
   * with 404 — and the reader must hold the `collector` or `validator`
   * Membership in the Visit's Project, mirroring the write path in
   * `recordCorrection` so read and write authorization for a Visit's
   * Corrections are identical; anyone else is refused with 403. A stored Visit
   * with no Corrections yields an empty list.
   */
  async listCorrections(
    personId: string,
    visitId: string,
  ): Promise<Correction[]> {
    const [current] = await this.db
      .select()
      .from(visit)
      .where(eq(visit.id, visitId))
      .limit(1);
    if (current === undefined) {
      throw new NotFoundException(`Visit ${visitId} does not exist`);
    }

    const [member] = await this.db
      .select({ id: membership.id })
      .from(membership)
      .where(
        and(
          eq(membership.personId, personId),
          eq(membership.projectId, current.projectId),
          inArray(membership.role, ['collector', 'validator']),
        ),
      )
      .limit(1);
    if (member === undefined) {
      throw new ForbiddenException(
        "only a collector or validator may list a Visit's Corrections",
      );
    }

    return this.db
      .select()
      .from(correction)
      .where(eq(correction.visitId, visitId))
      .orderBy(asc(correction.createdAt));
  }

  /**
   * Reads a stored Visit's Validation state (GLOSSARY.md Visit, Validation;
   * INV-013): its `state`, `validatorId` and `validatedAt`. The Visit must
   * exist — a missing id is refused with 404 — and the reader must hold the
   * `collector` or `validator` Membership in the Visit's Project, mirroring
   * the Corrections read in `listCorrections` so a Visit is never disclosed to
   * a non-Member; anyone else is refused with 403. A `submitted` Visit with no
   * Validation carries a null `validatorId` and `validatedAt`.
   */
  async getVisit(
    personId: string,
    visitId: string,
  ): Promise<VisitValidationState> {
    const [current] = await this.db
      .select()
      .from(visit)
      .where(eq(visit.id, visitId))
      .limit(1);
    if (current === undefined) {
      throw new NotFoundException(`Visit ${visitId} does not exist`);
    }

    const [member] = await this.db
      .select({ id: membership.id })
      .from(membership)
      .where(
        and(
          eq(membership.personId, personId),
          eq(membership.projectId, current.projectId),
          inArray(membership.role, ['collector', 'validator']),
        ),
      )
      .limit(1);
    if (member === undefined) {
      throw new ForbiddenException(
        'only a collector or validator may read a Visit',
      );
    }

    return {
      state: current.state,
      validatorId: current.validatorId,
      validatedAt: current.validatedAt,
    };
  }
}
