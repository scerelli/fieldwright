import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Module, type INestApplicationContext } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import {
  RedisContainer,
  type StartedRedisContainer,
} from '@testcontainers/redis';
import { Queue } from 'bullmq';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import { exportRecord, project, type ExportState } from '../src/db/schema.js';
import {
  EXPORT_ARTIFACT_STORAGE,
  type ExportArtifactStorage,
} from '../src/exports/export-artifact.storage.js';
import {
  EXPORT_GENERATORS,
  ExportGeneratorRegistry,
  ExportProcessor,
  type ExportGenerator,
} from '../src/exports/export.processor.js';
import { EXPORT_JOB_NAME } from '../src/exports/exports.queue.js';
import { ExportsStore } from '../src/exports/exports.store.js';
import { MEDIA_STORAGE } from '../src/media/media.storage.js';
import { MediaModule } from '../src/media/media.module.js';
import { createRedisConnection } from '../src/queue/redis.provider.js';
import { WORKER_QUEUE_NAME, createExportWorker } from '../src/worker.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

/** The one distinct artifact byte string this suite ever produces. */
const ARTIFACT = new TextEncoder().encode('ibis-export-artifact-bytes');
const ARTIFACT_SHA256 = createHash('sha256').update(ARTIFACT).digest('hex');

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

/**
 * A stand-in for a format generator (#46–#49 register the real ones): counts
 * its invocations and can be told to throw for its next `failNext` calls, so a
 * test drives the retry cap without a real format.
 */
class FakeGenerator implements ExportGenerator {
  calls = 0;
  private failuresRemaining = 0;

  constructor(readonly format: string) {}

  failNext(count: number): void {
    this.failuresRemaining = count;
  }

  reset(): void {
    this.calls = 0;
    this.failuresRemaining = 0;
  }

  async generate(): Promise<Uint8Array> {
    this.calls += 1;
    if (this.failuresRemaining > 0) {
      this.failuresRemaining -= 1;
      throw new Error('generator boom');
    }
    return ARTIFACT;
  }
}

const generators = [
  new FakeGenerator('csv'),
  new FakeGenerator('darwin_core'),
];

function generator(format: string): FakeGenerator {
  const found = generators.find((candidate) => candidate.format === format);
  if (found === undefined) {
    throw new Error(`no fake generator for ${format}`);
  }
  return found;
}

@Module({
  imports: [DatabaseModule, MediaModule],
  providers: [
    ExportsStore,
    ExportGeneratorRegistry,
    ExportProcessor,
    { provide: EXPORT_GENERATORS, useValue: generators },
    { provide: EXPORT_ARTIFACT_STORAGE, useExisting: MEDIA_STORAGE },
  ],
})
class TestModule {}

async function waitFor<T>(
  check: () => Promise<T | undefined>,
  timeoutMs = 20_000,
): Promise<T> {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    const value = await check();
    if (value !== undefined) {
      return value;
    }
    if (Date.now() > deadline) {
      throw new Error('timed out waiting for the export');
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
}

describe('exports worker', () => {
  let postgres: StartedPostgreSqlContainer;
  let redis: StartedRedisContainer;
  let app: INestApplicationContext;
  let db: NodePgDatabase;
  let store: ExportsStore;
  let artifacts: ExportArtifactStorage;
  let queue: Queue;
  let mediaRoot: string;
  let worker: ReturnType<typeof createExportWorker>;

  beforeAll(async () => {
    postgres = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    redis = await new RedisContainer('redis:7').start();
    mediaRoot = await mkdtemp(join(tmpdir(), 'ibis-exports-worker-'));

    process.env.DATABASE_URL = postgres.getConnectionUri();
    process.env.REDIS_URL = redis.getConnectionUrl();
    process.env.BETTER_AUTH_SECRET =
      'test-only-secret-at-least-thirty-two-characters';
    process.env.MEDIA_STORAGE_BACKEND = 'volume';
    process.env.MEDIA_ROOT = mediaRoot;

    const migrate = runDrizzleKitMigrate(process.env.DATABASE_URL!);
    if (migrate.status !== 0) {
      throw new Error(
        `drizzle-kit migrate failed: ${migrate.stderr}${migrate.stdout}`,
      );
    }

    app = await NestFactory.createApplicationContext(TestModule, {
      logger: false,
    });
    db = app.get<NodePgDatabase>(DATABASE);
    store = app.get(ExportsStore);
    artifacts = app.get<ExportArtifactStorage>(EXPORT_ARTIFACT_STORAGE);

    worker = createExportWorker(app, process.env.REDIS_URL);
    await worker.waitUntilReady();

    queue = new Queue(WORKER_QUEUE_NAME, {
      connection: createRedisConnection(process.env.REDIS_URL),
    });
  }, 240_000);

  beforeEach(async () => {
    await queue.obliterate({ force: true });
    for (const fake of generators) {
      fake.reset();
    }
  });

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await worker?.close();
      await queue?.close();
      await app.close();
      await pool.end();
    }
    await redis?.stop();
    await postgres?.stop();
    await rm(mediaRoot, { recursive: true, force: true });
  });

  async function seedProject(name = 'Export worker project'): Promise<string> {
    const [created] = await db
      .insert(project)
      .values({
        name,
        settings: { validationEnabled: false, sensitiveTaxaObfuscation: false },
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
      })
      .returning();
    return created!.id;
  }

  async function seedExport(
    projectId: string,
    format: string,
  ): Promise<string> {
    const [created] = await db
      .insert(exportRecord)
      .values({ projectId, format })
      .returning();
    return created!.id;
  }

  async function enqueue(
    exportId: string,
    format: string,
    attempts: number,
  ): Promise<void> {
    await queue.add(EXPORT_JOB_NAME, { exportId, format }, { attempts });
  }

  function waitForState(
    exportId: string,
    state: ExportState,
  ): Promise<{ id: string; state: ExportState }> {
    return waitFor(async () => {
      const found = await store.findById(exportId);
      return found !== null && found.state === state ? found : undefined;
    });
  }

  it('writes the artifact through the export artifact store and marks the export succeeded (C1)', async () => {
    const projectId = await seedProject();
    const exportId = await seedExport(projectId, 'csv');

    await enqueue(exportId, 'csv', 1);

    const succeeded = await waitForState(exportId, 'succeeded');
    expect(succeeded.state).toBe('succeeded');
    const stored = await store.findById(exportId);
    expect(stored!.storageKey).toBe(ARTIFACT_SHA256);
    expect(stored!.error).toBeNull();
    const bytes = await artifacts.fetch(stored!.storageKey!);
    expect(Buffer.from(bytes!)).toEqual(Buffer.from(ARTIFACT));
  }, 30_000);

  it("dispatches to the generator registered for the export's format (C2)", async () => {
    const projectId = await seedProject();
    const exportId = await seedExport(projectId, 'darwin_core');

    await enqueue(exportId, 'darwin_core', 1);

    await waitForState(exportId, 'succeeded');
    expect(generator('darwin_core').calls).toBe(1);
    expect(generator('csv').calls).toBe(0);
  }, 30_000);

  it('retries a job whose generator throws, up to the configured attempt cap (C3)', async () => {
    const projectId = await seedProject();
    const exportId = await seedExport(projectId, 'csv');
    generator('csv').failNext(1);

    await enqueue(exportId, 'csv', 2);

    await waitForState(exportId, 'succeeded');
    expect(generator('csv').calls).toBe(2);
  }, 30_000);

  it('applies the worker attempt cap when the enqueuer configured none (C3)', async () => {
    const projectId = await seedProject();
    const exportId = await seedExport(projectId, 'csv');
    generator('csv').failNext(1);

    await queue.add(EXPORT_JOB_NAME, { exportId, format: 'csv' });

    await waitForState(exportId, 'succeeded');
    expect(generator('csv').calls).toBe(2);
  }, 30_000);

  it('marks the export failed with the error after the attempt cap is reached (C4)', async () => {
    const projectId = await seedProject();
    const exportId = await seedExport(projectId, 'csv');
    generator('csv').failNext(Number.POSITIVE_INFINITY);

    await enqueue(exportId, 'csv', 2);

    await waitForState(exportId, 'failed');
    const stored = await store.findById(exportId);
    expect(generator('csv').calls).toBe(2);
    expect(stored!.state).toBe('failed');
    expect(stored!.error).toBe('generator boom');
    expect(stored!.storageKey).toBeNull();
  }, 30_000);

  it('marks the export failed when no generator is registered for its format', async () => {
    const projectId = await seedProject();
    const exportId = await seedExport(projectId, 'geopackage');

    await enqueue(exportId, 'geopackage', 1);

    await waitForState(exportId, 'failed');
    const stored = await store.findById(exportId);
    expect(stored!.error).toMatch(/geopackage/);
  }, 30_000);
});
