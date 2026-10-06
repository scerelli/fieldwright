/**
 * The server `taxonomic-references` module's versioned REST surface
 * (ARCHITECTURE.md, ADR-0020). `GET /api/v1/taxonomic-references/:id/versions/
 * :version` is auth-guarded, like every `/api/v1` controller, and returns the
 * immutable artifact the operator's reference volume holds for that id+version.
 * The surface is additive: an unknown query parameter is accepted and ignored.
 */
import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard.js';
import type { ReferenceArtifact } from './reference-artifact.js';
import { TaxonomicReferencesService } from './taxonomic-references.service.js';

@Controller('api/v1/taxonomic-references')
export class TaxonomicReferencesController {
  constructor(private readonly references: TaxonomicReferencesService) {}

  @UseGuards(AuthGuard)
  @Get(':id/versions/:version')
  get(
    @Param('id') id: string,
    @Param('version') version: string,
  ): Promise<ReferenceArtifact> {
    return this.references.get(id, version);
  }
}
