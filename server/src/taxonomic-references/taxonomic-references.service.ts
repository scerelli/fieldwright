/**
 * The server `taxonomic-references` module's read service (ARCHITECTURE.md,
 * ADR-0020): resolves a versioned reference artifact from the reference volume
 * by `id`+`version` and raises not-found when the volume holds none. The module
 * owns no aggregate — it serves operator-supplied files immutably.
 */
import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import type { ReferenceArtifact } from './reference-artifact.js';
import {
  REFERENCE_STORAGE,
  type ReferenceStorage,
} from './taxonomic-references.storage.js';

@Injectable()
export class TaxonomicReferencesService {
  constructor(
    @Inject(REFERENCE_STORAGE) private readonly storage: ReferenceStorage,
  ) {}

  /** Returns the artifact for `id`+`version`, or raises 404 when none is stored. */
  async get(id: string, version: string): Promise<ReferenceArtifact> {
    const artifact = await this.storage.readArtifact(id, version);
    if (artifact === null) {
      throw new NotFoundException();
    }
    return artifact;
  }
}
