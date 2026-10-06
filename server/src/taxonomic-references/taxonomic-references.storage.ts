/**
 * The `taxonomic-references` module's volume-backed artifact store (ADR-0020):
 * reads an operator-supplied artifact from `<root>/<id>/<version>.json` and
 * projects it onto the reference artifact format. A file is served as it is
 * found; the module writes nothing and owns no runtime aggregate.
 */
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import {
  parseReferenceArtifact,
  type ReferenceArtifact,
} from './reference-artifact.js';

/** DI token for the bound `ReferenceStorage` implementation. */
export const REFERENCE_STORAGE = 'REFERENCE_STORAGE';

/**
 * A path segment (reference `id` or `version`) that can name a file under the
 * reference root. It must start alphanumeric, so `.` and `..` are not segments
 * and an untrusted `id`/`version` can never traverse out of the root.
 */
export const REFERENCE_SEGMENT_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;

/**
 * A reference file that is present on the volume but is not a valid artifact:
 * either its bytes are not JSON, or the JSON is not a `ReferenceArtifact`. The
 * module names it (ARCHITECTURE.md, ADR-0020) rather than conflating it with an
 * absent file, so a broken operator import surfaces as a fixable error instead
 * of a silent 404.
 */
export class MalformedReferenceArtifactError extends Error {
  constructor(
    readonly id: string,
    readonly version: string,
    options?: { cause?: unknown },
  ) {
    super(`reference artifact ${id}@${version} is malformed`, options);
    this.name = 'MalformedReferenceArtifactError';
  }
}

export interface ReferenceStorage {
  /**
   * Returns the artifact stored for `id`+`version`, or `null` when the volume
   * holds no such file. A malformed segment and an absent file are both
   * not-found, so an untrusted path is never a lookup; a file that is present
   * but not a valid artifact throws `MalformedReferenceArtifactError`.
   */
  readArtifact(id: string, version: string): Promise<ReferenceArtifact | null>;
}

export function createReferenceVolumeStorage(root: string): ReferenceStorage {
  return {
    async readArtifact(
      id: string,
      version: string,
    ): Promise<ReferenceArtifact | null> {
      if (
        !REFERENCE_SEGMENT_PATTERN.test(id) ||
        !REFERENCE_SEGMENT_PATTERN.test(version)
      ) {
        return null;
      }

      let raw: string;
      try {
        raw = await readFile(join(root, id, `${version}.json`), 'utf8');
      } catch (error) {
        if (isNotFound(error)) {
          return null;
        }
        throw error;
      }

      let parsed: unknown;
      try {
        parsed = JSON.parse(raw);
      } catch (error) {
        throw new MalformedReferenceArtifactError(id, version, {
          cause: error,
        });
      }

      const artifact = parseReferenceArtifact(parsed);
      if (artifact === null) {
        throw new MalformedReferenceArtifactError(id, version);
      }
      return artifact;
    },
  };
}

/**
 * Whether a filesystem error means the artifact is simply not there. Beyond
 * ENOENT, an operator who left a file where a directory (or the reverse) is
 * expected makes the path unreachable too, so it is not-found rather than a
 * 500.
 */
function isNotFound(error: unknown): boolean {
  return ['ENOENT', 'ENOTDIR', 'EISDIR'].some((code) => hasCode(error, code));
}

function hasCode(error: unknown, code: string): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code?: unknown }).code === code
  );
}
