import { createHash } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  CreateBucketCommand,
  HeadObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import {
  MinioContainer,
  type StartedMinioContainer,
} from '@testcontainers/minio';
import type { Request } from 'express';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  loadMediaConfig,
  type MediaConfig,
  type S3MediaConfig,
} from '../src/media/media.config.js';
import { MediaController } from '../src/media/media.controller.js';
import { MediaService } from '../src/media/media.service.js';
import type { MediaStorage, StoredMedia } from '../src/media/media.storage.js';
import { createS3Storage } from '../src/media/s3.storage.js';
import { createVolumeStorage } from '../src/media/volume.storage.js';

const EVIDENCE = new TextEncoder().encode('ibis-s3-evidence-photo-bytes');
const EVIDENCE_SHA256 = createHash('sha256').update(EVIDENCE).digest('hex');
const DEDUPE = new TextEncoder().encode('ibis-s3-evidence-audio-bytes');
const DEDUPE_SHA256 = createHash('sha256').update(DEDUPE).digest('hex');
const OVERWRITE = new TextEncoder().encode('ibis-s3-overwrite-bytes');
const HASHED = new TextEncoder().encode('ibis-s3-hashed-bytes');
const SIZED = new TextEncoder().encode('ibis-s3-sized-bytes');

const MAX_UPLOAD_BYTES = 64;

/**
 * PUTs `bytes` to a stored upload, sending the required headers the API
 * returned. `Content-Length` is set by fetch from the body, so the signature
 * binds the size.
 */
function putUpload(
  stored: Pick<StoredMedia, 'uploadUrl' | 'uploadHeaders'>,
  bytes: Uint8Array,
): Promise<Response> {
  return fetch(stored.uploadUrl!, {
    method: 'PUT',
    body: Buffer.from(bytes),
    headers: stored.uploadHeaders ?? {},
  });
}

/**
 * A request shaped like the one the upload handler reads: a declared length and
 * an async-iterable body, exercising the same `readBytes` path the HTTP route
 * uses without a listening server.
 */
function requestOf(bytes: Uint8Array): Request {
  return {
    headers: { 'content-length': String(bytes.byteLength) },
    async *[Symbol.asyncIterator]() {
      yield Buffer.from(bytes);
    },
  } as unknown as Request;
}

function controllerFor(
  storage: MediaStorage,
  config: MediaConfig,
): MediaController {
  return new MediaController(new MediaService(storage), config);
}

const VOLUME_CONFIG: MediaConfig = {
  backend: 'volume',
  root: '/unused-in-this-suite',
  maxUploadBytes: MAX_UPLOAD_BYTES,
};

describe('media upload with the volume backend', () => {
  let root: string;

  beforeAll(async () => {
    root = await mkdtemp(join(tmpdir(), 'ibis-media-s3-volume-'));
  });

  afterAll(async () => {
    await rm(root, { recursive: true, force: true });
  });

  it('stores through the volume backend and returns no presigned URL (C2)', async () => {
    const storage = createVolumeStorage(root);
    const controller = controllerFor(storage, VOLUME_CONFIG);

    const stored = await controller.upload(requestOf(EVIDENCE));

    expect(stored.storageKey).toBe(EVIDENCE_SHA256);
    expect(stored.sha256).toBe(EVIDENCE_SHA256);
    expect(stored.uploadUrl).toBeUndefined();
    expect(stored.uploadHeaders).toBeUndefined();
    expect(Buffer.from((await storage.fetch(EVIDENCE_SHA256))!)).toEqual(
      Buffer.from(EVIDENCE),
    );
  });
});

describe('media upload with the S3 backend', () => {
  let minio: StartedMinioContainer;
  let bucket: string;
  let admin: S3Client;
  let s3Config: S3MediaConfig;

  beforeAll(async () => {
    minio = await new MinioContainer('minio/minio:latest').start();
    bucket = `ibis-evidence-${Date.now()}`;
    s3Config = {
      endpoint: minio.getConnectionUrl(),
      region: 'us-east-1',
      bucket,
      accessKeyId: minio.getUsername(),
      secretAccessKey: minio.getPassword(),
      forcePathStyle: true,
      presignExpirySeconds: 900,
    };
    admin = new S3Client({
      region: s3Config.region,
      endpoint: s3Config.endpoint,
      forcePathStyle: true,
      credentials: {
        accessKeyId: s3Config.accessKeyId,
        secretAccessKey: s3Config.secretAccessKey,
      },
    });
    await admin.send(new CreateBucketCommand({ Bucket: bucket }));
  }, 180_000);

  afterAll(async () => {
    admin?.destroy();
    await minio?.stop();
  });

  it('returns a presigned upload URL and the content-addressed storageKey (C1)', async () => {
    const storage = createS3Storage(s3Config);
    const controller = controllerFor(storage, {
      ...VOLUME_CONFIG,
      backend: 's3',
      s3: s3Config,
    });

    const stored = await controller.upload(requestOf(EVIDENCE));

    expect(stored.storageKey).toBe(EVIDENCE_SHA256);
    expect(stored.sha256).toBe(EVIDENCE_SHA256);
    expect(typeof stored.uploadUrl).toBe('string');
    expect(stored.uploadHeaders).toMatchObject({
      'If-None-Match': '*',
      'x-amz-checksum-sha256': createHash('sha256')
        .update(EVIDENCE)
        .digest('base64'),
    });

    const put = await putUpload(stored, EVIDENCE);
    expect(put.status, await put.clone().text()).toBe(200);

    const fetched = await storage.fetch(EVIDENCE_SHA256);
    expect(fetched).not.toBeNull();
    expect(Buffer.from(fetched!)).toEqual(Buffer.from(EVIDENCE));
  });

  it('keys by the lowercase-hex SHA-256 and does not overwrite an existing object (C3)', async () => {
    const storage = createS3Storage(s3Config);

    const first = await storage.store(DEDUPE);
    expect(first.storageKey).toBe(DEDUPE_SHA256);
    expect(first.storageKey).toMatch(/^[0-9a-f]{64}$/);
    expect(typeof first.uploadUrl).toBe('string');

    const put = await putUpload(first, DEDUPE);
    expect(put.status, await put.clone().text()).toBe(200);

    const before = await admin.send(
      new HeadObjectCommand({ Bucket: bucket, Key: DEDUPE_SHA256 }),
    );
    await new Promise((resolve) => setTimeout(resolve, 1100));

    const second = await storage.store(DEDUPE);

    expect(second.storageKey).toBe(DEDUPE_SHA256);
    expect(second.sha256).toBe(DEDUPE_SHA256);
    expect(second.uploadUrl).toBeUndefined();

    const after = await admin.send(
      new HeadObjectCommand({ Bucket: bucket, Key: DEDUPE_SHA256 }),
    );
    expect(after.LastModified?.getTime()).toBe(before.LastModified?.getTime());
    expect(Buffer.from((await storage.fetch(DEDUPE_SHA256))!)).toEqual(
      Buffer.from(DEDUPE),
    );
  });

  it('rejects an overwrite of an existing object through the same presigned URL (C3)', async () => {
    const storage = createS3Storage(s3Config);
    const stored = await storage.store(OVERWRITE);

    const first = await putUpload(stored, OVERWRITE);
    expect(first.status, await first.clone().text()).toBe(200);

    const overwrite = await putUpload(stored, OVERWRITE);
    expect(overwrite.status).toBe(412);
  });

  it('rejects a PUT larger than the size the API accepted, including over maxUploadBytes (C3)', async () => {
    const storage = createS3Storage(s3Config);
    expect(SIZED.byteLength).toBeLessThanOrEqual(MAX_UPLOAD_BYTES);
    const stored = await storage.store(SIZED);

    const oversized = new Uint8Array(MAX_UPLOAD_BYTES + 1).fill(0x42);
    const response = await putUpload(stored, oversized);

    expect(response.status).toBe(403);
  });

  it('rejects a PUT whose bytes do not hash to the storageKey (C3)', async () => {
    const storage = createS3Storage(s3Config);
    const stored = await storage.store(HASHED);

    const different = Uint8Array.from(HASHED);
    different[0] = different[0]! ^ 0xff;
    expect(different.byteLength).toBe(HASHED.byteLength);

    const response = await putUpload(stored, different);

    expect(response.status).toBe(400);
  });
});

describe('loadMediaConfig with S3 settings', () => {
  it('selects the S3 backend and reads its settings from the environment', () => {
    const config = loadMediaConfig({
      MEDIA_STORAGE_BACKEND: 's3',
      MEDIA_S3_ENDPOINT: 'http://minio:9000',
      MEDIA_S3_BUCKET: 'ibis-evidence',
      MEDIA_S3_ACCESS_KEY_ID: 'minioadmin',
      MEDIA_S3_SECRET_ACCESS_KEY: 'minioadmin',
    });

    expect(config.backend).toBe('s3');
    expect(config.s3).toMatchObject({
      endpoint: 'http://minio:9000',
      region: 'us-east-1',
      bucket: 'ibis-evidence',
      forcePathStyle: true,
    });
  });

  it('defaults to the volume backend with no S3 settings present', () => {
    const config = loadMediaConfig({});

    expect(config.backend).toBe('volume');
    expect(config.s3).toBeUndefined();
  });

  it('fails loud when S3 is selected without its required settings', () => {
    expect(() => loadMediaConfig({ MEDIA_STORAGE_BACKEND: 's3' })).toThrow(
      /MEDIA_S3_BUCKET/,
    );
  });

  it('honours an explicit path-style override', () => {
    const config = loadMediaConfig({
      MEDIA_STORAGE_BACKEND: 's3',
      MEDIA_S3_ENDPOINT: 'http://minio:9000',
      MEDIA_S3_FORCE_PATH_STYLE: 'false',
      MEDIA_S3_BUCKET: 'ibis-evidence',
      MEDIA_S3_ACCESS_KEY_ID: 'minioadmin',
      MEDIA_S3_SECRET_ACCESS_KEY: 'minioadmin',
    });

    expect(config.s3?.forcePathStyle).toBe(false);
  });
});
