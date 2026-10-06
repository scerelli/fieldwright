/**
 * The server `visits` module's versioned REST surface (ARCHITECTURE.md,
 * ADR-0011). `POST /api/v1/visits` is auth-guarded and idempotent: the
 * client-generated UUIDv7 `id` identifies the Visit, so a repeat submission of
 * the same id returns the already-stored Visit without writing a second row,
 * and unknown fields are ignored (the `/api/v1` compatibility surface is
 * additive only). Under ADR-0021 a Visit is accepted as it stands: its Survey
 * period, Protocol version and pinned reference are optional and a Detection
 * carries a resolved `taxon` or a provisional name, so a provisional Visit is
 * stored rather than rejected (INV-020 – INV-022). A submitted Visit is
 * immutable (INV-001): this module exposes no update route.
 */
import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsISO8601,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { AuthGuard, type Person } from '../auth/auth.guard.js';
import { CurrentPerson } from '../auth/current-person.decorator.js';
import { DATABASE } from '../db/database.provider.js';
import {
  visit,
  type Correction,
  type MeasurementProvenance,
  type Visit,
} from '../db/schema.js';
import {
  VisitsService,
  type StoreSubmittedVisitInput,
  type VisitValidationState,
} from './visits.service.js';

export class DeterminationDto {
  @IsString()
  @IsNotEmpty()
  taxon!: string;

  @IsOptional()
  @IsIn(['cf.', 'aff.', 'sp.'])
  qualifier?: 'cf.' | 'aff.' | 'sp.';

  @IsOptional()
  @IsString()
  specimenCode?: string;

  @IsString()
  @IsNotEmpty()
  determiner!: string;

  @IsISO8601()
  date!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  replacesIndex?: number;
}

export class DetectionDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  taxon?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  provisionalName?: string;

  @IsBoolean()
  detected!: boolean;

  @IsString()
  @IsNotEmpty()
  method!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  count?: number;

  @IsOptional()
  @IsBoolean()
  opportunistic?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DeterminationDto)
  determinations?: DeterminationDto[];
}

export class MeasurementDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  detectionIndex?: number;

  @IsString()
  value!: string;

  @IsString()
  unit!: string;

  @IsObject()
  provenance!: MeasurementProvenance;
}

export class EvidenceDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  detectionIndex?: number;

  @IsIn(['photo', 'audio'])
  kind!: 'photo' | 'audio';

  @IsString()
  @IsNotEmpty()
  storageKey!: string;

  @IsString()
  @IsNotEmpty()
  sha256!: string;
}

export class SubmitVisitDto {
  @IsUUID()
  id!: string;

  @IsUUID()
  projectId!: string;

  @IsUUID()
  siteId!: string;

  @IsOptional()
  @IsUUID()
  surveyPeriodId?: string | null;

  @IsOptional()
  @IsUUID()
  protocolVersionId?: string | null;

  @IsObject()
  effort!: Record<string, unknown>;

  @IsISO8601()
  startedAt!: string;

  @IsOptional()
  @IsISO8601()
  endedAt?: string | null;

  @IsISO8601()
  submittedAt!: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DetectionDto)
  detections?: DetectionDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MeasurementDto)
  measurements?: MeasurementDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => EvidenceDto)
  evidence?: EvidenceDto[];
}

/**
 * The Validation a validator records against a submitted Visit (GLOSSARY.md
 * Validation): acceptance (`validated`) or rejection (`rejected`).
 */
export class ApplyValidationDto {
  @IsIn(['validated', 'rejected'])
  state!: 'validated' | 'rejected';
}

/**
 * The Correction a collector or validator records against a stored Visit
 * (GLOSSARY.md Correction): the reason and the change payload. The author and
 * the recording time are resolved server-side, so the body carries neither.
 */
export class RecordCorrectionDto {
  @IsString()
  @IsNotEmpty()
  reason!: string;

  @IsObject()
  payload!: Record<string, unknown>;
}

@Controller('api/v1/visits')
@UsePipes(
  new ValidationPipe({
    transform: true,
    whitelist: true,
  }),
)
export class VisitsController {
  constructor(
    private readonly visits: VisitsService,
    @Inject(DATABASE) private readonly db: NodePgDatabase,
  ) {}

  /**
   * Stores a submitted Visit, or returns the one already stored under the same
   * id. `whitelist` strips unknown fields without rejecting them; a payload
   * missing a required field is rejected with 400 before this method runs. The
   * client-generated id is the idempotency key: a repeated submission raises the
   * Visit primary-key conflict, which the endpoint resolves to the already
   * stored Visit — so it still stores exactly one, and a concurrent duplicate
   * is handled by the same path rather than a check-then-insert race.
   */
  @UseGuards(AuthGuard)
  @Post()
  async submit(@Body() dto: SubmitVisitDto): Promise<Visit> {
    try {
      return await this.visits.storeSubmittedVisit(toStoreInput(dto));
    } catch (error) {
      if (!isUniqueViolation(error)) {
        throw error;
      }
      const existing = await this.findVisit(dto.id);
      if (existing === undefined) {
        throw error;
      }
      return existing;
    }
  }

  /**
   * Records a Validation against a `submitted` Visit: acceptance (`validated`)
   * or rejection (`rejected`) (INV-013). Requires the `validator` Membership
   * in the Visit's Project; a Project with validation disabled, or a Visit
   * that is not `submitted`, is refused and left unchanged. The change writes
   * only the Visit's validation columns, so a rejected Visit keeps its
   * submitted data (INV-001).
   */
  @UseGuards(AuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post(':id/validation')
  async applyValidation(
    @CurrentPerson() person: Person,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ApplyValidationDto,
  ): Promise<Visit> {
    return this.visits.applyValidation(person.id, id, dto.state);
  }

  /**
   * Records a Correction against a stored Visit (GLOSSARY.md Correction,
   * INV-001): one append-only `correction` row carrying the authenticated
   * author, the recording time, the reason and the change payload. The stored
   * Visit is never touched — every one of its
   * columns is left exactly as submitted. Requires a `collector` or
   * `validator` Membership in the Visit's Project; a Visit in `in_progress` or
   * `ended` is not yet stored and is refused.
   */
  @UseGuards(AuthGuard)
  @Post(':id/corrections')
  async recordCorrection(
    @CurrentPerson() person: Person,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RecordCorrectionDto,
  ): Promise<Correction> {
    return this.visits.recordCorrection(person.id, id, {
      reason: dto.reason,
      payload: dto.payload,
    });
  }

  /**
   * Lists a stored Visit's Corrections (GLOSSARY.md Correction, INV-001),
   * oldest first, each carrying its author, `createdAt`, `reason` and
   * `payload`; a stored Visit with no Corrections returns an empty list, and a
   * Visit id that does not exist is refused with 404. Read authorization
   * mirrors `recordCorrection`'s write path — a `collector` or `validator`
   * Membership in the Visit's Project is required — so a Visit's Corrections
   * are read by the same people who may record them; anyone else is refused
   * with 403.
   */
  @UseGuards(AuthGuard)
  @Get(':id/corrections')
  async listCorrections(
    @CurrentPerson() person: Person,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<Correction[]> {
    return this.visits.listCorrections(person.id, id);
  }

  /**
   * Reads a stored Visit's Validation state (GLOSSARY.md Visit, Validation;
   * INV-013): its `state`, `validatorId` and `validatedAt`, so the client can
   * display a Visit's Validation status. A Visit id that does not exist is
   * refused with 404. Read authorization mirrors the Corrections read — a
   * `collector` or `validator` Membership in the Visit's Project is required —
   * so a Visit is never disclosed to a non-Member; anyone else is refused with
   * 403. A `submitted` Visit with no Validation has a null `validatorId` and
   * `validatedAt`.
   */
  @UseGuards(AuthGuard)
  @Get(':id')
  async getVisit(
    @CurrentPerson() person: Person,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<VisitValidationState> {
    return this.visits.getVisit(person.id, id);
  }

  private async findVisit(id: string): Promise<Visit | undefined> {
    const [row] = await this.db
      .select()
      .from(visit)
      .where(eq(visit.id, id))
      .limit(1);
    return row;
  }
}

function isUniqueViolation(error: unknown): boolean {
  let current: unknown = error;
  while (typeof current === 'object' && current !== null) {
    if ('code' in current && (current as { code?: unknown }).code === '23505') {
      return true;
    }
    current =
      'cause' in current ? (current as { cause?: unknown }).cause : undefined;
  }
  return false;
}

function toStoreInput(dto: SubmitVisitDto): StoreSubmittedVisitInput {
  return {
    id: dto.id,
    projectId: dto.projectId,
    siteId: dto.siteId,
    surveyPeriodId: dto.surveyPeriodId ?? null,
    protocolVersionId: dto.protocolVersionId ?? null,
    effort: dto.effort,
    startedAt: new Date(dto.startedAt),
    endedAt: dto.endedAt ? new Date(dto.endedAt) : null,
    submittedAt: new Date(dto.submittedAt),
    detections: dto.detections?.map((entry) => ({
      taxon: entry.taxon ?? null,
      provisionalName: entry.provisionalName ?? null,
      detected: entry.detected,
      method: entry.method,
      count: entry.count ?? null,
      opportunistic: entry.opportunistic ?? false,
      determinations: entry.determinations?.map((determinationEntry) => ({
        taxon: determinationEntry.taxon,
        qualifier: determinationEntry.qualifier ?? null,
        specimenCode: determinationEntry.specimenCode ?? null,
        determiner: determinationEntry.determiner,
        date: determinationEntry.date,
        replacesIndex: determinationEntry.replacesIndex ?? null,
      })),
    })),
    measurements: dto.measurements?.map((entry) => ({
      detectionIndex: entry.detectionIndex ?? null,
      value: entry.value,
      unit: entry.unit,
      provenance: entry.provenance,
    })),
    evidence: dto.evidence?.map((entry) => ({
      detectionIndex: entry.detectionIndex ?? null,
      kind: entry.kind,
      storageKey: entry.storageKey,
      sha256: entry.sha256,
    })),
  };
}
