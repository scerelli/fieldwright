import { createHash } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  type GetObjectCommandOutput,
  GetObjectCommand,
  HeadObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { mockClient } from 'aws-sdk-client-mock';
import type { Request } from 'express';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  loadMediaConfig,
  type MediaConfig,
  type S3MediaConfig,
} from '../src/media/media.config.js';
import { MediaController } from '../src/media/media.controller.js';
import { MediaService } from '../src/media/media.service.js';
import type { MediaStorage } from '../src/media/media.storage.js';
import { createS3Storage } from '../src/media/s3.storage.js';
import { createVolumeStorage } from '../src/media/volume.storage.js';

const EVIDENCE = new TextEncoder().encode('ibis-s3-evidence-photo-bytes');
const EVIDENCE_SHA256 = createHash('sha256').update(EVIDENCE).digest('hex');
const EVIDENCE_CHECKSUM = createHash('sha256')
  .update(EVIDENCE)
  .digest('base64');

const MAX_UPLOAD_BYTES = 64;

/**
 * The S3 backend is exercised against a mocked AWS SDK client: `send` is
 * stubbed, so no network call and no object-store image is needed, while the
 * presigning itself is the real `S3Client` + `getSignedUrl` (ADR-0012). What
 * the mock proves is the security-critical part: the presigned URL binds the
 * upload to the content hash, the size, and a no-overwrite precondition.
 */
const s3Mock = mockClient(S3Client);

const S3_CONFIG: S3MediaConfig = {
  endpoint: 'http://127.0.0.1:9000',
  region: 'us-east-1',
  bucket: 'ibis-evidence',
  accessKeyId: 'minioadmin',
  secretAccessKey: 'minioadmin',
  forcePathStyle: true,
  presignExpirySeconds: 900,
};

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

/** A not-found error named the way S3 models a missing key on HEAD/GET. */
function notFound(name: 'NotFound' | 'NoSuchKey'): Error {
  return Object.assign(new Error(`${name}: no such object`), { name });
}

/** A GetObject body whose only used method is `transformToByteArray`. */
function bodyOf(bytes: Uint8Array): GetObjectCommandOutput['Body'] {
  return {
    transformToByteArray: async () => bytes,
  } as unknown as GetObjectCommandOutput['Body'];
}

/** The headers SigV4 actually signs for a presigned URL, lowercased. */
function signedHeaders(url: string): Set<string> {
  const raw =
    new URL(url).searchParams.get('X-Amz-SignedHeaders')?.split(';') ?? [];
  return new Set(raw.filter((header) => header !== ''));
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
  beforeEach(() => {
    s3Mock.reset();
  });

  afterAll(() => {
    s3Mock.restore();
  });

  it('returns a presigned upload URL bound to the content hash and size (C1)', async () => {
    s3Mock.on(HeadObjectCommand).rejects(notFound('NotFound'));
    const controller = controllerFor(createS3Storage(S3_CONFIG), {
      ...VOLUME_CONFIG,
      backend: 's3',
      s3: S3_CONFIG,
    });

    const stored = await controller.upload(requestOf(EVIDENCE));

    expect(stored.storageKey).toBe(EVIDENCE_SHA256);
    expect(stored.sha256).toBe(EVIDENCE_SHA256);
    expect(typeof stored.uploadUrl).toBe('string');
    expect(stored.uploadHeaders).toEqual({
      'If-None-Match': '*',
      'x-amz-checksum-sha256': EVIDENCE_CHECKSUM,
    });

    const signed = signedHeaders(stored.uploadUrl!);
    expect(signed).toEqual(
      new Set([
        'content-length',
        'host',
        'if-none-match',
        'x-amz-checksum-sha256',
      ]),
    );

    const url = new URL(stored.uploadUrl!);
    expect(url.pathname).toBe(`/ibis-evidence/${EVIDENCE_SHA256}`);
    // The checksum stays a signed header rather than a hoisted query param, so
    // an S3-compatible store actually verifies it (ADR-0012).
    expect(url.searchParams.has('x-amz-checksum-sha256')).toBe(false);
    expect(url.searchParams.has('X-Amz-Checksum-Sha256')).toBe(false);
    expect(url.searchParams.get('X-Amz-Signature')).not.toBeNull();
  });

  it.each(['NotFound', 'NoSuchKey'] as const)(
    'presigns the lowercase-hex SHA-256 key when HeadObject reports %s (C3)',
    async (name) => {
      s3Mock.on(HeadObjectCommand).rejects(notFound(name));

      const stored = await createS3Storage(S3_CONFIG).store(EVIDENCE);

      expect(stored.storageKey).toBe(EVIDENCE_SHA256);
      expect(stored.storageKey).toMatch(/^[0-9a-f]{64}$/);
      expect(stored.sha256).toBe(EVIDENCE_SHA256);
      expect(typeof stored.uploadUrl).toBe('string');
    },
  );

  it('returns no uploadUrl when HeadObject finds the object, so it is never overwritten (C3)', async () => {
    s3Mock
      .on(HeadObjectCommand)
      .rejectsOnce(notFound('NotFound'))
      .resolvesOnce({});
    const storage = createS3Storage(S3_CONFIG);

    const first = await storage.store(EVIDENCE);
    expect(typeof first.uploadUrl).toBe('string');

    const second = await storage.store(EVIDENCE);

    expect(second.storageKey).toBe(EVIDENCE_SHA256);
    expect(second.sha256).toBe(EVIDENCE_SHA256);
    expect(second.uploadUrl).toBeUndefined();
    expect(second.uploadHeaders).toBeUndefined();
  });

  it('fetches the stored bytes returned by GetObject (C1)', async () => {
    s3Mock.on(GetObjectCommand).resolves({ Body: bodyOf(EVIDENCE) });
    const storage = createS3Storage(S3_CONFIG);

    const bytes = await storage.fetch(EVIDENCE_SHA256);

    expect(bytes).not.toBeNull();
    expect(Buffer.from(bytes!)).toEqual(Buffer.from(EVIDENCE));
  });

  it('returns null when GetObject reports the object is gone (C3)', async () => {
    s3Mock.on(GetObjectCommand).rejects(notFound('NoSuchKey'));
    const storage = createS3Storage(S3_CONFIG);

    expect(await storage.fetch(EVIDENCE_SHA256)).toBeNull();
  });

  it('reports not-found for a malformed key without calling the object store (C3)', async () => {
    const storage = createS3Storage(S3_CONFIG);

    expect(await storage.fetch('../secret')).toBeNull();
    expect(s3Mock.commandCalls(GetObjectCommand).length).toBe(0);
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
