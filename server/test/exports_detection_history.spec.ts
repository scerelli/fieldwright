import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
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
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import {
  detection,
  exportRecord,
  project,
  protocolVersion,
  site,
  surveyPeriod,
  visit,
  type Export,
} from '../src/db/schema.js';
import { buildDetectionHistoryMatrix } from '../src/exports/detection-history.js';
import {
  DETECTION_HISTORY_BUILDER,
  DetectionHistoryGenerator,
} from '../src/exports/detection-history.generator.js';
import {
  EXPORT_ARTIFACT_STORAGE,
  type ExportArtifactStorage,
} from '../src/exports/export-artifact.storage.js';
import {
  EXPORT_GENERATORS,
  ExportGeneratorRegistry,
  ExportProcessor,
} from '../src/exports/export.processor.js';
import { exportGeneratorsFactory } from '../src/exports/exports.module.js';
import { EXPORT_JOB_NAME } from '../src/exports/exports.queue.js';
import { ExportsStore } from '../src/exports/exports.store.js';
import { MEDIA_STORAGE } from '../src/media/media.storage.js';
import { MediaModule } from '../src/media/media.module.js';
import { createRedisConnection } from '../src/queue/redis.provider.js';
import { WORKER_QUEUE_NAME, createExportWorker } from '../src/worker.js';
import { targetTaxaOf } from '../src/visits/visit-rules.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

/** The committed golden fixture the processed artifact must equal byte-for-byte. */
const GOLDEN_PATH = fileURLToPath(
  new URL('./fixtures/detection_history.golden.csv', import.meta.url),
);

@Module({
  imports: [DatabaseModule, MediaModule],
  providers: [
    ExportsStore,
    DetectionHistoryGenerator,
    ExportGeneratorRegistry,
    ExportProcessor,
    {
      provide: DETECTION_HISTORY_BUILDER,
      useValue: buildDetectionHistoryMatrix,
    },
    {
      provide: EXPORT_GENERATORS,
      useFactory: exportGeneratorsFactory,
      inject: [DetectionHistoryGenerator],
    },
    { provide: EXPORT_ARTIFACT_STORAGE, useExisting: MEDIA_STORAGE },
  ],
})
class TestModule {}

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

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

describe('detection-history CSV golden fixture', () => {
  let postgres: StartedPostgreSqlContainer;
  let redis: StartedRedisContainer;
  let app: INestApplicationContext;
  let db: NodePgDatabase;
  let store: ExportsStore;
  let artifacts: ExportArtifactStorage;
  let queue: Queue;
  let mediaRoot: string;
  let worker: ReturnType<typeof createExportWorker>;
  let protocolVersionId: string;

  beforeAll(async () => {
    postgres = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    redis = await new RedisContainer('redis:7').start();
    mediaRoot = await mkdtemp(join(tmpdir(), 'ibis-exports-golden-'));

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

    protocolVersionId = await seedGoldenProject();
  }, 240_000);

  beforeEach(async () => {
    await queue.obliterate({ force: true });
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

  /**
   * Seeds one Project whose Protocol version declares a three-entry Target
   * list, two Sites, two Survey periods and two Visits whose Detections cover a
   * detection, a non-detection and an opportunistic Detection. Every submitted
   * Visit records a Detection for each of its Target list taxa (INV-002), so no
   * cell is left unreachable; the opportunistic Detection adds no column and
   * fills no cell (INV-003). Returns the Protocol version the Visits reference.
   */
  async function seedGoldenProject(): Promise<string> {
    const [created] = await db
      .insert(project)
      .values({
        name: 'Detection history golden project',
        settings: { validationEnabled: false, sensitiveTaxaObfuscation: false },
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
      })
      .returning();

    const [protocol] = await db
      .insert(protocolVersion)
      .values({
        projectId: created!.id,
        protocolId: 'alpine-birds-2026',
        version: 1,
        document: {
          protocolId: 'alpine-birds-2026',
          version: 1,
          targetList: [
            { taxonRef: 'Aves|Turdus|merula' },
            { taxonRef: 'Aves|Erithacus|rubecula' },
            { taxonRef: 'Aves|Parus|major' },
          ],
        },
      })
      .returning();

    await db.insert(site).values([
      {
        id: '00000000-0000-0000-0000-0000000000a1',
        projectId: created!.id,
        name: 'Plot A',
      },
      {
        id: '00000000-0000-0000-0000-0000000000a2',
        projectId: created!.id,
        name: 'Plot B',
      },
    ]);
    await db.insert(surveyPeriod).values([
      {
        id: '00000000-0000-0000-0000-0000000000b1',
        projectId: created!.id,
        name: 'Spring',
        startDate: '2024-01-01',
        endDate: '2024-03-31',
      },
      {
        id: '00000000-0000-0000-0000-0000000000b2',
        projectId: created!.id,
        name: 'Summer',
        startDate: '2024-04-01',
        endDate: '2024-06-30',
      },
    ]);
    await db.insert(visit).values([
      {
        id: '00000000-0000-0000-0000-0000000000c1',
        projectId: created!.id,
        siteId: '00000000-0000-0000-0000-0000000000a1',
        surveyPeriodId: '00000000-0000-0000-0000-0000000000b1',
        protocolVersionId: protocol!.id,
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
        state: 'submitted',
        effort: {},
        startedAt: new Date('2024-01-01T08:00:00.000Z'),
        submittedAt: new Date('2024-01-01T09:00:00.000Z'),
      },
      {
        id: '00000000-0000-0000-0000-0000000000c2',
        projectId: created!.id,
        siteId: '00000000-0000-0000-0000-0000000000a2',
        surveyPeriodId: '00000000-0000-0000-0000-0000000000b2',
        protocolVersionId: protocol!.id,
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
        state: 'submitted',
        effort: {},
        startedAt: new Date('2024-02-01T08:00:00.000Z'),
        submittedAt: new Date('2024-02-01T09:00:00.000Z'),
      },
    ]);
    await db.insert(detection).values([
      {
        visitId: '00000000-0000-0000-0000-0000000000c1',
        taxon: 'Aves|Turdus|merula',
        detected: true,
        method: 'visual',
      },
      {
        visitId: '00000000-0000-0000-0000-0000000000c1',
        taxon: 'Aves|Erithacus|rubecula',
        detected: false,
        method: 'acoustic',
      },
      {
        visitId: '00000000-0000-0000-0000-0000000000c1',
        taxon: 'Aves|Parus|major',
        detected: false,
        method: 'visual',
      },
      {
        visitId: '00000000-0000-0000-0000-0000000000c1',
        taxon: 'Aves|Corvus|corone',
        detected: true,
        method: 'visual',
        opportunistic: true,
      },
      {
        visitId: '00000000-0000-0000-0000-0000000000c2',
        taxon: 'Aves|Turdus|merula',
        detected: false,
        method: 'visual',
      },
      {
        visitId: '00000000-0000-0000-0000-0000000000c2',
        taxon: 'Aves|Erithacus|rubecula',
        detected: true,
        method: 'acoustic',
      },
      {
        visitId: '00000000-0000-0000-0000-0000000000c2',
        taxon: 'Aves|Parus|major',
        detected: true,
        method: 'acoustic',
      },
    ]);

    return protocol!.id;
  }

  async function processCsvExport(): Promise<{
    stored: Export;
    bytes: Uint8Array;
  }> {
    const [projectRow] = await db
      .select({ id: protocolVersion.projectId })
      .from(protocolVersion)
      .where(eq(protocolVersion.id, protocolVersionId));
    const [record] = await db
      .insert(exportRecord)
      .values({ projectId: projectRow!.id, format: 'csv' })
      .returning();

    await queue.add(
      EXPORT_JOB_NAME,
      { exportId: record!.id, format: 'csv' },
      { attempts: 1 },
    );

    const stored = await waitFor(async () => {
      const found = await store.findById(record!.id);
      return found !== null && found.state === 'succeeded' ? found : undefined;
    });
    const bytes = await artifacts.fetch(stored.storageKey!);
    return { stored, bytes: bytes! };
  }

  it('processes a csv Export through the worker and stores bytes byte-identical to the golden fixture (C1)', async () => {
    const { stored, bytes } = await processCsvExport();
    const golden = await readFile(GOLDEN_PATH);

    expect(stored.state).toBe('succeeded');
    expect(stored.error).toBeNull();
    expect(stored.storageKey).toBe(
      createHash('sha256').update(golden).digest('hex'),
    );
    expect(Buffer.from(bytes)).toEqual(golden);
  }, 30_000);

  it('heads the golden fixture with one column per Target list taxonRef of the seeded Protocol version after the key columns (C2)', async () => {
    const [protocol] = await db
      .select({ document: protocolVersion.document })
      .from(protocolVersion)
      .where(eq(protocolVersion.id, protocolVersionId));
    const targetRefs = targetTaxaOf(protocol!.document);

    const golden = await readFile(GOLDEN_PATH, 'utf8');
    const header = golden.split('\r\n')[0]!.split(',');

    expect(header).toEqual([
      'site_id',
      'survey_period_id',
      'visit_id',
      'started_at',
      ...targetRefs,
    ]);
  });
});
