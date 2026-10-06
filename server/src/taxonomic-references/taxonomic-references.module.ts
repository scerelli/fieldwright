/**
 * The served application's `taxonomic-references` module (ARCHITECTURE.md): the
 * auth-guarded, versioned read surface that serves an operator-supplied
 * reference artifact from the reference volume by `id`+`version`, immutably
 * (ADR-0020). It owns no runtime aggregate and never stores a reference in
 * Postgres.
 */
import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DatabaseModule } from '../db/database.module.js';
import { TaxonomicReferencesController } from './taxonomic-references.controller.js';
import {
  loadTaxonomicReferencesConfig,
  TAXONOMIC_REFERENCES_CONFIG,
  type TaxonomicReferencesConfig,
} from './taxonomic-references.config.js';
import { TaxonomicReferencesService } from './taxonomic-references.service.js';
import {
  createReferenceVolumeStorage,
  REFERENCE_STORAGE,
  type ReferenceStorage,
} from './taxonomic-references.storage.js';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [TaxonomicReferencesController],
  providers: [
    {
      provide: TAXONOMIC_REFERENCES_CONFIG,
      useFactory: () => loadTaxonomicReferencesConfig(),
    },
    {
      provide: REFERENCE_STORAGE,
      useFactory: (config: TaxonomicReferencesConfig): ReferenceStorage =>
        createReferenceVolumeStorage(config.root),
      inject: [TAXONOMIC_REFERENCES_CONFIG],
    },
    TaxonomicReferencesService,
  ],
  exports: [REFERENCE_STORAGE, TaxonomicReferencesService],
})
export class TaxonomicReferencesModule {}
