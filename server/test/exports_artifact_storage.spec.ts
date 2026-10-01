import { createHash } from 'node:crypto';
import { mkdtemp, readFile, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  type GetObjectCommandOutput,
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { mockClient } from 'aws-sdk-client-mock';
import { Module } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import {
  EXPORT_ARTIFACT_STORAGE,
  type ExportArtifactStorage,
} from '../src/exports/export-artifact.storage.js';
import { ExportsModule } from '../src/exports/exports.module.js';
import type { S3MediaConfig } from '../src/media/media.config.js';
import { MEDIA_STORAGE } from '../src/media/media.storage.js';
import { createS3Storage } from '../src/media/s3.storage.js';
import { createVolumeStorage } from '../src/media/volume.storage.js';

/**
 * The one distinct artifact byte string this suite ever stores. A generated
 * Export artifact is content-addressed and immutable (ADR-0007): the worker
 * writes it server-side, unlike the Evidence contract's presigned client PUT
 * (ADR-0012).
 */
const ARTIFACT = new TextEncoder().encode('ibis-export-artifact-bytes');
const ARTIFACT_SHA256 = createHash('sha256').update(ARTIFACT).digest('hex');

const S3_CONFIG: S3MediaConfig = {
  endpoint: 'http://127.0.0.1:9000',
  region: 'us-east-1',
  bucket: 'ibis-exports',
  accessKeyId: 'minioadmin',
  secretAccessKey: 'minioadmin',
  forcePathStyle: true,
  presignExpirySeconds: 900,
};

const s3Mock = mockClient(S3Client);

/** A not-found error named the way S3 models a missing key on HEAD. */
function notFound(name: 'NotFound' | 'NoSuchKey'): Error {
  return Object.assign(new Error(`${name}: no such object`), { name });
}

/** A GetObject body whose only used method is `transformToByteArray`. */
function bodyOf(bytes: Uint8Array): GetObjectCommandOutput['Body'] {
  return {
    transformToByteArray: async () => bytes,
  } as unknown as GetObjectCommandOutput['Body'];
}

describe('volume export artifact storage', () => {
  let root: string;
  let storage: ExportArtifactStorage;

  beforeEach(async () => {
    root = await mkdtemp(join(tmpdir(), 'ibis-export-artifact-'));
    storage = createVolumeStorage(root);
  });

  afterEach(async () => {
    await rm(root, { recursive: true, force: true });
  });

  it('writes the artifact at its lowercase-hex SHA-256 key and returns that key (C1)', async () => {
    const key = await storage.put(ARTIFACT);

    expect(key).toBe(ARTIFACT_SHA256);
    expect(key).toMatch(/^[0-9a-f]{64}$/);
    expect(createHash('sha256').update(ARTIFACT).digest('hex')).toBe(key);
    expect(Buffer.from(await readFile(join(root, key)))).toEqual(
      Buffer.from(ARTIFACT),
    );
  });

  it('fetches the exact bytes that were stored (C2)', async () => {
    const key = await storage.put(ARTIFACT);

    const bytes = await storage.fetch(key);

    expect(bytes).not.toBeNull();
    expect(Buffer.from(bytes!)).toEqual(Buffer.from(ARTIFACT));
  });

  it('returns the same key for identical bytes and never rewrites the stored artifact (C3)', async () => {
    const first = await storage.put(ARTIFACT);
    const target = join(root, first);
    const before = await stat(target);

    await new Promise((resolve) => setTimeout(resolve, 20));

    const second = await storage.put(ARTIFACT);
    const after = await stat(target);

    expect(second).toBe(first);
    expect(after.mtimeMs).toBe(before.mtimeMs);
    expect(Buffer.from(await readFile(target))).toEqual(Buffer.from(ARTIFACT));
  });
});

describe('S3 export artifact storage', () => {
  beforeEach(() => {
    s3Mock.reset();
  });

  afterEach(() => {
    s3Mock.restore();
  });

  it('stores the artifact server-side with PutObject and fetches it byte-identical (C4)', async () => {
    s3Mock.on(HeadObjectCommand).rejects(notFound('NotFound'));
    s3Mock.on(PutObjectCommand).resolves({});
    s3Mock.on(GetObjectCommand).resolves({ Body: bodyOf(ARTIFACT) });
    const storage: ExportArtifactStorage = createS3Storage(S3_CONFIG);

    const key = await storage.put(ARTIFACT);

    expect(key).toBe(ARTIFACT_SHA256);
    const puts = s3Mock.commandCalls(PutObjectCommand);
    expect(puts).toHaveLength(1);
    expect(puts[0]!.args[0].input).toMatchObject({
      Bucket: S3_CONFIG.bucket,
      Key: ARTIFACT_SHA256,
    });
    expect(Buffer.from(puts[0]!.args[0].input.Body as Uint8Array)).toEqual(
      Buffer.from(ARTIFACT),
    );

    const bytes = await storage.fetch(key);
    expect(bytes).not.toBeNull();
    expect(Buffer.from(bytes!)).toEqual(Buffer.from(ARTIFACT));
  });

  it('returns the key without a server-side write when the object already exists (C4)', async () => {
    s3Mock.on(HeadObjectCommand).resolves({});
    const storage = createS3Storage(S3_CONFIG);

    const key = await storage.put(ARTIFACT);

    expect(key).toBe(ARTIFACT_SHA256);
    expect(s3Mock.commandCalls(PutObjectCommand)).toHaveLength(0);
  });
});

@Module({ imports: [ExportsModule] })
class BindingModule {}

describe('EXPORT_ARTIFACT_STORAGE binding', () => {
  it('binds the media backend the exports module writes artifacts through (C1, C5)', async () => {
    process.env.DATABASE_URL = 'postgres://ibis:ibis@127.0.0.1:5432/ibis';
    process.env.REDIS_URL = 'redis://127.0.0.1:6379';
    process.env.BETTER_AUTH_SECRET =
      'test-only-secret-at-least-thirty-two-characters';
    const root = await mkdtemp(join(tmpdir(), 'ibis-export-binding-'));
    process.env.MEDIA_ROOT = root;
    process.env.MEDIA_STORAGE_BACKEND = 'volume';

    const app = await NestFactory.create(BindingModule, {
      logger: false,
      abortOnError: false,
    });
    try {
      const artifacts = app.get<ExportArtifactStorage>(EXPORT_ARTIFACT_STORAGE);

      expect(artifacts).toBe(app.get(MEDIA_STORAGE));

      const key = await artifacts.put(ARTIFACT);
      expect(key).toBe(ARTIFACT_SHA256);
      expect(Buffer.from((await artifacts.fetch(key))!)).toEqual(
        Buffer.from(ARTIFACT),
      );
    } finally {
      await app.close();
      await rm(root, { recursive: true, force: true });
    }
  });
});
