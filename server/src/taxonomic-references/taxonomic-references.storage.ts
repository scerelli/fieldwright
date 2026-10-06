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

export interface ReferenceStorage {
  /**
   * Returns the artifact stored for `id`+`version`, or `null` when the volume
   * holds no such file. A malformed segment, an absent file, and a file that is
   * not an artifact are all not-found, so an untrusted path is never a lookup.
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

      return parseReferenceArtifact(parseJson(raw));
    },
  };
}

function parseJson(raw: string): unknown {
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
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
