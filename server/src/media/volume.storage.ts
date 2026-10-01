/**
 * The default `MediaStorage` backend (ADR-0007): a Docker volume mounted at the
 * media root. A file is written once at its content-hashed key and never
 * overwritten, so identical bytes dedupe and a stored Evidence file is
 * immutable (ADR-0012).
 */
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import type { MediaStorage, StoredMedia } from './media.storage.js';

/** A storage key is exactly the lowercase-hex SHA-256 of the stored bytes. */
const STORAGE_KEY_PATTERN = /^[0-9a-f]{64}$/;

export function createVolumeStorage(root: string): MediaStorage {
  return {
    async store(bytes: Uint8Array): Promise<StoredMedia> {
      const sha256 = createHash('sha256').update(bytes).digest('hex');
      await mkdir(root, { recursive: true });

      try {
        await writeFile(join(root, sha256), bytes, { flag: 'wx' });
      } catch (error) {
        if (!hasCode(error, 'EEXIST')) {
          throw error;
        }
      }

      return { storageKey: sha256, sha256 };
    },

    async fetch(storageKey: string): Promise<Uint8Array | null> {
      if (!STORAGE_KEY_PATTERN.test(storageKey)) {
        return null;
      }

      try {
        return await readFile(join(root, storageKey));
      } catch (error) {
        if (hasCode(error, 'ENOENT')) {
          return null;
        }
        throw error;
      }
    },
  };
}

function hasCode(error: unknown, code: string): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code?: unknown }).code === code
  );
}
