import { spawnSync } from 'node:child_process';
import { mkdtemp, rm } from 'node:fs/promises';
import type { AddressInfo } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Module, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import {
  RedisContainer,
  type StartedRedisContainer,
} from '@testcontainers/redis';
import { Queue, type Job } from 'bullmq';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { AuthModule } from '../src/auth/auth.module.js';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import {
  exportRecord,
  membership,
  project,
  type ExportState,
} from '../src/db/schema.js';
import {
  EXPORT_ARTIFACT_STORAGE,
  type ExportArtifactStorage,
} from '../src/exports/export-artifact.storage.js';
import { ExportsModule } from '../src/exports/exports.module.js';
import { createRedisConnection } from '../src/queue/redis.provider.js';
import { WORKER_QUEUE_NAME } from '../src/worker.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const EMAIL = 'exporter@example.com';
const PASSWORD = 'correct-horse-battery-staple';
const ARTIFACT = new TextEncoder().encode('ibis-export-artifact-bytes');

const JOB_TYPES = [
  'waiting',
  'active',
  'delayed',
  'prioritized',
  'completed',
  'failed',
  'waiting-children',
] as const;

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

@Module({
  imports: [ExportsModule, AuthModule, DatabaseModule],
})
class TestModule {}

describe('/api/v1/exports', () => {
  let postgres: StartedPostgreSqlContainer;
  let redis: StartedRedisContainer;
  let app: INestApplication;
  let baseUrl: string;
  let mediaRoot: string;
  let cookie: string;
  let exporterId: string;
  let db: NodePgDatabase;
  let artifacts: ExportArtifactStorage;
  let queue: Queue;

  beforeAll(async () => {
    postgres = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    redis = await new RedisContainer('redis:7').start();
    mediaRoot = await mkdtemp(join(tmpdir(), 'ibis-exports-api-'));

    process.env.DATABASE_URL = postgres.getConnectionUri();
    process.env.REDIS_URL = redis.getConnectionUrl();
    process.env.BETTER_AUTH_SECRET =
      'test-only-secret-at-least-thirty-two-characters';
    process.env.MEDIA_STORAGE_BACKEND = 'volume';
    process.env.MEDIA_ROOT = mediaRoot;

    const migrate = runDrizzleKitMigrate(process.env.DATABASE_URL);
    if (migrate.status !== 0) {
      throw new Error(
        `drizzle-kit migrate failed: ${migrate.stderr}${migrate.stdout}`,
      );
    }

    app = await NestFactory.create(TestModule, {
      logger: false,
      abortOnError: false,
    });
    await app.listen(0, '127.0.0.1');
    const address = app.getHttpServer().address() as AddressInfo;
    baseUrl = `http://127.0.0.1:${address.port}`;
    db = app.get<NodePgDatabase>(DATABASE);
    artifacts = app.get<ExportArtifactStorage>(EXPORT_ARTIFACT_STORAGE);
    queue = new Queue(WORKER_QUEUE_NAME, {
      connection: createRedisConnection(process.env.REDIS_URL),
    });

    const exporter = await signUpAndSignIn(EMAIL);
    cookie = exporter.cookie;
    exporterId = exporter.id;
  }, 240_000);

  async function signUpAndSignIn(
    email: string,
  ): Promise<{ id: string; cookie: string }> {
    const signUp = await fetch(`${baseUrl}/api/auth/sign-up/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: PASSWORD, name: 'X' }),
    });
    if (signUp.status !== 200) {
      throw new Error(`sign-up failed: ${await signUp.clone().text()}`);
    }

    const signIn = await fetch(`${baseUrl}/api/auth/sign-in/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: PASSWORD }),
    });
    if (signIn.status !== 200) {
      throw new Error(`sign-in failed: ${await signIn.clone().text()}`);
    }

    const signedIn = (await signIn.json()) as { user: { id: string } };
    const token = signIn.headers
      .getSetCookie()
      .find((value) => value.includes('better-auth.session_token')); // glossary:allow Better Auth's auth-session cookie
    if (token === undefined) {
      throw new Error('sign-in returned no auth cookie');
    }
    return { id: signedIn.user.id, cookie: token.split(';')[0]! };
  }

  beforeEach(async () => {
    await queue.obliterate({ force: true });
  });

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await queue.close();
      await app.close();
      await pool.end();
    }
    await redis?.stop();
    await postgres?.stop();
    await rm(mediaRoot, { recursive: true, force: true });
  });

  async function seedProject(name = 'Export API project'): Promise<string> {
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

  async function addMembership(
    personId: string,
    projectId: string,
    role: 'creator' | 'collector' | 'validator',
  ): Promise<void> {
    await db.insert(membership).values({ personId, projectId, role });
  }

  async function seedExport(
    projectId: string,
    state: ExportState = 'requested',
    storageKey: string | null = null,
  ): Promise<string> {
    const [created] = await db
      .insert(exportRecord)
      .values({ projectId, format: 'darwin_core', state, storageKey })
      .returning();
    return created!.id;
  }

  function jobs(): Promise<Job[]> {
    return queue.getJobs([...JOB_TYPES]);
  }

  function requestExport(
    body: unknown,
    headers: Record<string, string> = {},
  ) {
    return fetch(`${baseUrl}/api/v1/exports`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: JSON.stringify(body),
    });
  }

  function getExport(exportId: string, headers: Record<string, string> = {}) {
    return fetch(`${baseUrl}/api/v1/exports/${exportId}`, { headers });
  }

  function getArtifact(exportId: string, headers: Record<string, string> = {}) {
    return fetch(`${baseUrl}/api/v1/exports/${exportId}/artifact`, { headers });
  }

  it('creates one export record and enqueues exactly one job for a Member (C1)', async () => {
    const projectId = await seedProject();
    await addMembership(exporterId, projectId, 'collector');

    const response = await requestExport(
      { projectId, format: 'darwin_core' },
      { cookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const stored = await db
      .select()
      .from(exportRecord)
      .where(eq(exportRecord.projectId, projectId));
    expect(stored).toHaveLength(1);
    expect(stored[0]!.format).toBe('darwin_core');
    expect(stored[0]!.state).toBe('requested');

    const enqueued = await jobs();
    expect(enqueued).toHaveLength(1);
  });

  it('enqueues the export id and requested format on the job (C2)', async () => {
    const projectId = await seedProject();
    await addMembership(exporterId, projectId, 'creator');

    const response = await requestExport(
      { projectId, format: 'geopackage' },
      { cookie },
    );
    const body = (await response.json()) as { id: string };

    const enqueued = await jobs();
    expect(enqueued).toHaveLength(1);
    expect(enqueued[0]!.data).toEqual({
      exportId: body.id,
      format: 'geopackage',
    });
  });

  it('refuses a non-Member with 403 and enqueues no job (C3)', async () => {
    const projectId = await seedProject();
    const outsider = await signUpAndSignIn('export-outsider@example.com');

    const response = await requestExport(
      { projectId, format: 'csv' },
      { cookie: outsider.cookie },
    );

    expect(response.status, await response.clone().text()).toBe(403);
    expect(
      await db
        .select()
        .from(exportRecord)
        .where(eq(exportRecord.projectId, projectId)),
    ).toHaveLength(0);
    expect(await jobs()).toHaveLength(0);
  });

  it("returns the export's current state to a Member of its Project (C4)", async () => {
    const projectId = await seedProject();
    await addMembership(exporterId, projectId, 'collector');
    const exportId = await seedExport(projectId, 'processing');

    const response = await getExport(exportId, { cookie });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as { id: string; state: string };
    expect(body.id).toBe(exportId);
    expect(body.state).toBe('processing');
  });

  it('refuses a status read by a non-Member with 403 (C4)', async () => {
    const projectId = await seedProject();
    const outsider = await signUpAndSignIn('export-read-outsider@example.com');
    const exportId = await seedExport(projectId, 'processing');

    const response = await getExport(exportId, { cookie: outsider.cookie });

    expect(response.status, await response.clone().text()).toBe(403);
    const body = (await response.json()) as Record<string, unknown>;
    expect(body.state).toBeUndefined();
  });

  it('streams the stored artifact bytes of a succeeded export to a Member (C5)', async () => {
    const projectId = await seedProject();
    await addMembership(exporterId, projectId, 'collector');
    const storageKey = await artifacts.put(ARTIFACT);
    const exportId = await seedExport(projectId, 'succeeded', storageKey);

    const response = await getArtifact(exportId, { cookie });

    expect(response.status, await response.clone().text()).toBe(200);
    expect(
      Buffer.from(await response.arrayBuffer()),
    ).toEqual(Buffer.from(ARTIFACT));
  });

  it('refuses an artifact download by a non-Member with 403 (C5)', async () => {
    const projectId = await seedProject();
    const outsider = await signUpAndSignIn('export-artifact-outsider@example.com');
    const storageKey = await artifacts.put(ARTIFACT);
    const exportId = await seedExport(projectId, 'succeeded', storageKey);

    const response = await getArtifact(exportId, { cookie: outsider.cookie });

    expect(response.status, await response.clone().text()).toBe(403);
  });

  it('refuses an unauthenticated request to any /api/v1/exports route with 401 (C6)', async () => {
    const projectId = await seedProject();
    const exportId = await seedExport(projectId, 'requested');

    const post = await requestExport({ projectId, format: 'csv' });
    const status = await getExport(exportId);
    const artifact = await getArtifact(exportId);

    expect(post.status).toBe(401);
    expect(status.status).toBe(401);
    expect(artifact.status).toBe(401);
  });
});
