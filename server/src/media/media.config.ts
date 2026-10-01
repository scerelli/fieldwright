/**
 * Configuration for the `media` module (ARCHITECTURE.md): which storage backend
 * serves Evidence files, where the volume backend keeps them, and the largest
 * upload it accepts. All are read from the environment, so the Compose
 * deployment that mounts the `media` volume at /data/media needs no code change
 * (ADR-0007, ADR-0012).
 */

/** Injection token for the resolved `MediaConfig`. */
export const MEDIA_CONFIG = 'MEDIA_CONFIG';

/** The storage backends this build implements. S3 is documented but not yet wired. */
export type MediaBackend = 'volume';

export interface MediaConfig {
  backend: MediaBackend;
  root: string;
  /** Largest Evidence upload accepted, in bytes; anything larger is a 413. */
  maxUploadBytes: number;
}

export const DEFAULT_MEDIA_BACKEND: MediaBackend = 'volume';
export const DEFAULT_MEDIA_ROOT = '/data/media';
/** Sane default cap for a photo or audio Evidence file (25 MiB). */
export const DEFAULT_MEDIA_MAX_UPLOAD_BYTES = 25 * 1024 * 1024;

export function loadMediaConfig(
  env: NodeJS.ProcessEnv = process.env,
): MediaConfig {
  const backend =
    env.MEDIA_STORAGE_BACKEND === undefined || env.MEDIA_STORAGE_BACKEND === ''
      ? DEFAULT_MEDIA_BACKEND
      : env.MEDIA_STORAGE_BACKEND;
  if (backend !== 'volume') {
    throw new Error(
      `MEDIA_STORAGE_BACKEND "${backend}" is not supported: only the volume backend is implemented`,
    );
  }

  const root =
    env.MEDIA_ROOT === undefined || env.MEDIA_ROOT === ''
      ? DEFAULT_MEDIA_ROOT
      : env.MEDIA_ROOT;

  const rawMax = env.MEDIA_MAX_UPLOAD_BYTES;
  const maxUploadBytes =
    rawMax === undefined || rawMax === ''
      ? DEFAULT_MEDIA_MAX_UPLOAD_BYTES
      : Number(rawMax);
  if (!Number.isSafeInteger(maxUploadBytes) || maxUploadBytes <= 0) {
    throw new Error(
      `MEDIA_MAX_UPLOAD_BYTES "${rawMax}" is not a positive integer`,
    );
  }

  return { backend, root, maxUploadBytes };
}
