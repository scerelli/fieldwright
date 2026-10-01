/**
 * Configuration for the `media` module (ARCHITECTURE.md): which storage backend
 * serves Evidence files, where the volume backend keeps them, the largest
 * upload it accepts, and — when S3 is selected — the S3-compatible settings. All
 * are read from the environment, so the Compose deployment that mounts the
 * `media` volume at /data/media needs no code change, and an operator opting
 * into S3 only sets the S3 settings (ADR-0007, ADR-0012).
 */

/** Injection token for the resolved `MediaConfig`. */
export const MEDIA_CONFIG = 'MEDIA_CONFIG';

/** The storage backends this build implements. */
export type MediaBackend = 'volume' | 's3';

/** The S3-compatible settings, present only when `backend` is `'s3'`. */
export interface S3MediaConfig {
  /** Endpoint of the S3-compatible service; omit for AWS S3's regional endpoints. */
  endpoint?: string;
  region: string;
  bucket: string;
  accessKeyId: string;
  secretAccessKey: string;
  /** Path-style addressing (`endpoint/bucket/key`); MinIO needs it. */
  forcePathStyle: boolean;
  /** Lifetime of a presigned upload URL, in seconds. */
  presignExpirySeconds: number;
}

export interface MediaConfig {
  backend: MediaBackend;
  root: string;
  /** Largest Evidence upload accepted, in bytes; anything larger is a 413. */
  maxUploadBytes: number;
  s3?: S3MediaConfig;
}

export const DEFAULT_MEDIA_BACKEND: MediaBackend = 'volume';
export const DEFAULT_MEDIA_ROOT = '/data/media';
/** Sane default cap for a photo or audio Evidence file (25 MiB). */
export const DEFAULT_MEDIA_MAX_UPLOAD_BYTES = 25 * 1024 * 1024;
export const DEFAULT_S3_REGION = 'us-east-1';
/** Sane default lifetime for a presigned upload URL (15 minutes). */
export const DEFAULT_S3_PRESIGN_EXPIRY_SECONDS = 15 * 60;

export function loadMediaConfig(
  env: NodeJS.ProcessEnv = process.env,
): MediaConfig {
  const backend =
    env.MEDIA_STORAGE_BACKEND === undefined || env.MEDIA_STORAGE_BACKEND === ''
      ? DEFAULT_MEDIA_BACKEND
      : env.MEDIA_STORAGE_BACKEND;
  if (backend !== 'volume' && backend !== 's3') {
    throw new Error(
      `MEDIA_STORAGE_BACKEND "${backend}" is not supported: expected "volume" or "s3"`,
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

  if (backend !== 's3') {
    return { backend, root, maxUploadBytes };
  }

  return { backend, root, maxUploadBytes, s3: loadS3Config(env, backend) };
}

function loadS3Config(env: NodeJS.ProcessEnv, backend: string): S3MediaConfig {
  const missing: string[] = [];
  const bucket = required(env.MEDIA_S3_BUCKET, 'MEDIA_S3_BUCKET', missing);
  const accessKeyId = required(
    env.MEDIA_S3_ACCESS_KEY_ID,
    'MEDIA_S3_ACCESS_KEY_ID',
    missing,
  );
  const secretAccessKey = required(
    env.MEDIA_S3_SECRET_ACCESS_KEY,
    'MEDIA_S3_SECRET_ACCESS_KEY',
    missing,
  );
  if (missing.length > 0) {
    throw new Error(
      `MEDIA_STORAGE_BACKEND "${backend}" requires ${missing.join(', ')}`,
    );
  }

  const endpoint =
    env.MEDIA_S3_ENDPOINT === undefined || env.MEDIA_S3_ENDPOINT === ''
      ? undefined
      : env.MEDIA_S3_ENDPOINT;
  const region = env.MEDIA_S3_REGION || DEFAULT_S3_REGION;

  const rawExpiry = env.MEDIA_S3_PRESIGN_EXPIRY_SECONDS;
  const presignExpirySeconds =
    rawExpiry === undefined || rawExpiry === ''
      ? DEFAULT_S3_PRESIGN_EXPIRY_SECONDS
      : Number(rawExpiry);
  if (
    !Number.isSafeInteger(presignExpirySeconds) ||
    presignExpirySeconds <= 0
  ) {
    throw new Error(
      `MEDIA_S3_PRESIGN_EXPIRY_SECONDS "${rawExpiry}" is not a positive integer`,
    );
  }

  const forcePathStyle = parseBoolean(
    env.MEDIA_S3_FORCE_PATH_STYLE,
    endpoint !== undefined,
  );

  return {
    endpoint,
    region,
    bucket: bucket!,
    accessKeyId: accessKeyId!,
    secretAccessKey: secretAccessKey!,
    forcePathStyle,
    presignExpirySeconds,
  };
}

function required(
  value: string | undefined,
  name: string,
  missing: string[],
): string | undefined {
  if (value === undefined || value === '') {
    missing.push(name);
    return undefined;
  }
  return value;
}

function parseBoolean(raw: string | undefined, fallback: boolean): boolean {
  if (raw === undefined || raw === '') {
    return fallback;
  }
  if (raw === 'true' || raw === '1') {
    return true;
  }
  if (raw === 'false' || raw === '0') {
    return false;
  }
  throw new Error(`"${raw}" is not a boolean (expected true or false)`);
}
