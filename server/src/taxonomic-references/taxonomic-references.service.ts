/**
 * The server `taxonomic-references` module's read service (ARCHITECTURE.md,
 * ADR-0020): resolves a versioned reference artifact from the reference volume
 * by `id`+`version` and raises not-found when the volume holds none. The module
 * owns no aggregate — it serves operator-supplied files immutably.
 */
import {
  Inject,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import type { ReferenceArtifact } from './reference-artifact.js';
import {
  MalformedReferenceArtifactError,
  REFERENCE_STORAGE,
  type ReferenceStorage,
} from './taxonomic-references.storage.js';

@Injectable()
export class TaxonomicReferencesService {
  constructor(
    @Inject(REFERENCE_STORAGE) private readonly storage: ReferenceStorage,
  ) {}

  /**
   * Returns the artifact for `id`+`version`. Raises 404 when the volume holds
   * none; a file that is present but malformed is a named error the operator
   * must fix, surfaced as 500 rather than conflated with not-found.
   */
  async get(id: string, version: string): Promise<ReferenceArtifact> {
    let artifact: ReferenceArtifact | null;
    try {
      artifact = await this.storage.readArtifact(id, version);
    } catch (error) {
      if (error instanceof MalformedReferenceArtifactError) {
        throw new InternalServerErrorException(error.message);
      }
      throw error;
    }
    if (artifact === null) {
      throw new NotFoundException();
    }
    return artifact;
  }
}
