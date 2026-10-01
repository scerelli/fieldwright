/**
 * The server `exports` module's versioned REST surface (ARCHITECTURE.md,
 * ADR-0008, ADR-0011). `POST /api/v1/exports` is auth-guarded: it records one
 * Export and enqueues one job. `GET /api/v1/exports/:id` returns its state and
 * `GET /api/v1/exports/:id/artifact` streams a succeeded Export's stored bytes.
 * Every route requires authentication and is scoped to a Membership in the
 * Export's Project by the service, so an Export is never disclosed to a
 * non-Member. Unknown fields are ignored (the `/api/v1` compatibility surface
 * is additive only).
 */
import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  StreamableFile,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { IsNotEmpty, IsString, IsUUID } from 'class-validator';
import { AuthGuard, type Person } from '../auth/auth.guard.js';
import { CurrentPerson } from '../auth/current-person.decorator.js';
import type { Export } from '../db/schema.js';
import { ExportsService } from './exports.service.js';

/** A request to export a Project's data in the given format. */
export class RequestExportDto {
  @IsUUID()
  projectId!: string;

  @IsString()
  @IsNotEmpty()
  format!: string;
}

@Controller('api/v1/exports')
@UsePipes(
  new ValidationPipe({
    transform: true,
    whitelist: true,
  }),
)
export class ExportsController {
  constructor(private readonly exports: ExportsService) {}

  /**
   * Records one Export for the requested Project and enqueues exactly one job
   * carrying its id and format. The caller must be a Member of the Project;
   * anyone else is refused with 403 and no job is enqueued.
   */
  @UseGuards(AuthGuard)
  @Post()
  async request(
    @CurrentPerson() person: Person,
    @Body() dto: RequestExportDto,
  ): Promise<Export> {
    return this.exports.request(person.id, dto.projectId, dto.format);
  }

  /**
   * Returns the Export's current state to a Member of its Project; a caller
   * with no Membership is refused with 403, and a missing id with 404.
   */
  @UseGuards(AuthGuard)
  @Get(':id')
  async get(
    @CurrentPerson() person: Person,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<Export> {
    return this.exports.get(person.id, id);
  }

  /**
   * Streams a succeeded Export's stored artifact bytes to a Member of its
   * Project; a caller with no Membership is refused with 403, and an Export
   * with no stored artifact with 404.
   */
  @UseGuards(AuthGuard)
  @Get(':id/artifact')
  async artifact(
    @CurrentPerson() person: Person,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<StreamableFile> {
    const bytes = await this.exports.getArtifact(person.id, id);
    return new StreamableFile(Buffer.from(bytes), {
      type: 'application/octet-stream',
    });
  }
}
