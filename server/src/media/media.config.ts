/**
 * Configuration for the `media` module (ARCHITECTURE.md): which storage backend
 * serves Evidence files and where the volume backend keeps them. Both are read
 * from the environment, so the Compose deployment that mounts the `media`
 * volume at /data/media needs no code change (ADR-0007, ADR-0012).
 */

/** The storage backends this build implements. S3 is documented but not yet wired. */
export type MediaBackend = 'volume';

export interface MediaConfig {
  backend: MediaBackend;
  root: string;
}

export const DEFAULT_MEDIA_BACKEND: MediaBackend = 'volume';
export const DEFAULT_MEDIA_ROOT = '/data/media';

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

  return { backend, root };
}
