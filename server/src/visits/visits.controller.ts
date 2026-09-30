/**
 * The server `visits` module's versioned REST surface (ARCHITECTURE.md,
 * ADR-0011). `POST /api/v1/visits` is auth-guarded and idempotent: the
 * client-generated UUIDv7 `id` identifies the Visit, so a repeat submission of
 * the same id returns the already-stored Visit without writing a second row,
 * and unknown fields are ignored (the `/api/v1` compatibility surface is
 * additive only). A submitted Visit is immutable (INV-001): this module
 * exposes no update route.
 */
import {
  Body,
  Controller,
  Inject,
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
import { AuthGuard } from '../auth/auth.guard.js';
import { DATABASE } from '../db/database.provider.js';
import { visit, type MeasurementProvenance, type Visit } from '../db/schema.js';
import {
  VisitsService,
  type StoreSubmittedVisitInput,
} from './visits.service.js';

export class DetectionDto {
  @IsString()
  @IsNotEmpty()
  taxon!: string;

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

  @IsUUID()
  surveyPeriodId!: string;

  @IsUUID()
  protocolVersionId!: string;

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
    surveyPeriodId: dto.surveyPeriodId,
    protocolVersionId: dto.protocolVersionId,
    effort: dto.effort,
    startedAt: new Date(dto.startedAt),
    endedAt: dto.endedAt ? new Date(dto.endedAt) : null,
    submittedAt: new Date(dto.submittedAt),
    detections: dto.detections?.map((entry) => ({
      taxon: entry.taxon,
      detected: entry.detected,
      method: entry.method,
      count: entry.count ?? null,
      opportunistic: entry.opportunistic ?? false,
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
