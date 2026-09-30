import { spawnSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import type { AddressInfo } from 'node:net';
import { fileURLToPath } from 'node:url';
import { Module, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AuthModule } from '../src/auth/auth.module.js';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import {
  detection,
  determination,
  project,
  protocolVersion,
  site,
  surveyPeriod,
} from '../src/db/schema.js';
import { VisitsModule } from '../src/visits/visits.module.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const EMAIL = 'determiner@example.com';
const PASSWORD = 'correct-horse-battery-staple';

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

/** A client-generated UUIDv7 (DOMAIN.md: a Visit's identity). */
function uuidv7(): string {
  const bytes = randomBytes(16);
  const timestamp = Date.now();
  bytes[0] = Math.floor(timestamp / 2 ** 40) & 0xff;
  bytes[1] = Math.floor(timestamp / 2 ** 32) & 0xff;
  bytes[2] = Math.floor(timestamp / 2 ** 24) & 0xff;
  bytes[3] = Math.floor(timestamp / 2 ** 16) & 0xff;
  bytes[4] = Math.floor(timestamp / 2 ** 8) & 0xff;
  bytes[5] = timestamp & 0xff;
  bytes[6] = (bytes[6] & 0x0f) | 0x70;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

@Module({
  imports: [VisitsModule, AuthModule, DatabaseModule],
})
class TestModule {}

interface SeedReferences {
  projectId: string;
  siteId: string;
  surveyPeriodId: string;
  protocolVersionId: string;
}

describe('Determinations persisted with a submitted Visit', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;
  let app: INestApplication;
  let baseUrl: string;
  let cookie: string;
  let db: NodePgDatabase;

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    databaseUrl = container.getConnectionUri();
    process.env.DATABASE_URL = databaseUrl;
    process.env.BETTER_AUTH_SECRET =
      'test-only-secret-at-least-thirty-two-characters';

    const migrate = runDrizzleKitMigrate(databaseUrl);
    if (migrate.status !== 0) {
      throw new Error(
        `drizzle-kit migrate failed: ${migrate.stderr}${migrate.stdout}`,
      );
    }

    app = await NestFactory.create(TestModule, {
      logger: false,
      abortOnError: false,
    });
    await app.listen(0);
    const address = app.getHttpServer().address() as AddressInfo;
    baseUrl = `http://127.0.0.1:${address.port}`;
    db = app.get<NodePgDatabase>(DATABASE);

    const signUp = await fetch(`${baseUrl}/api/auth/sign-up/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: EMAIL, password: PASSWORD, name: 'D' }),
    });
    if (signUp.status !== 200) {
      throw new Error(`sign-up failed: ${await signUp.clone().text()}`);
    }

    const signIn = await fetch(`${baseUrl}/api/auth/sign-in/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: EMAIL, password: PASSWORD }),
    });
    if (signIn.status !== 200) {
      throw new Error(`sign-in failed: ${await signIn.clone().text()}`);
    }

    const token = signIn.headers
      .getSetCookie()
      .find((value) => value.includes('better-auth.session_token')); // glossary:allow Better Auth's auth-session cookie, not the Visit
    if (token === undefined) {
      throw new Error('sign-in returned no auth cookie');
    }
    cookie = token.split(';')[0]!;
  }, 180_000);

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await container?.stop();
  });

  async function seedReferences(): Promise<SeedReferences> {
    const [createdProject] = await db
      .insert(project)
      .values({
        name: 'Determination project',
        settings: { validationEnabled: true, sensitiveTaxaObfuscation: false },
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
      })
      .returning();

    const [createdSite] = await db
      .insert(site)
      .values({
        projectId: createdProject.id,
        name: 'Plot A',
        geom: JSON.stringify({ type: 'Point', coordinates: [11.1, 46.1] }),
      })
      .returning();

    const [createdPeriod] = await db
      .insert(surveyPeriod)
      .values({
        projectId: createdProject.id,
        name: 'Spring 2026',
        startDate: '2026-03-01',
        endDate: '2026-05-31',
      })
      .returning();

    const [createdProtocol] = await db
      .insert(protocolVersion)
      .values({
        projectId: createdProject.id,
        protocolId: 'standard',
        version: 1,
        document: { protocolId: 'standard', version: 1 },
      })
      .returning();

    return {
      projectId: createdProject.id,
      siteId: createdSite.id,
      surveyPeriodId: createdPeriod.id,
      protocolVersionId: createdProtocol.id,
    };
  }

  function visitPayload(
    refs: SeedReferences,
    id: string,
    determinations: unknown[],
  ) {
    return {
      id,
      projectId: refs.projectId,
      siteId: refs.siteId,
      surveyPeriodId: refs.surveyPeriodId,
      protocolVersionId: refs.protocolVersionId,
      effort: {
        durationMinutes: 60,
        observers: ['A. Collector'],
        detectionMethods: ['visual'],
      },
      startedAt: '2026-04-01T08:00:00Z',
      endedAt: '2026-04-01T09:00:00Z',
      submittedAt: '2026-04-01T09:05:00Z',
      detections: [
        {
          taxon: 'Anthus trivialis',
          detected: true,
          method: 'visual',
          determinations,
        },
      ],
    };
  }

  function submitVisit(body: unknown) {
    return fetch(`${baseUrl}/api/v1/visits`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', cookie },
      body: JSON.stringify(body),
    });
  }

  async function determinationsForVisit(visitId: string) {
    const [storedDetection] = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, visitId));
    if (storedDetection === undefined) {
      return [];
    }
    return db
      .select()
      .from(determination)
      .where(eq(determination.detectionId, storedDetection.id));
  }

  it('persists the Determinations of a submitted Visit', async () => {
    const refs = await seedReferences();
    const id = uuidv7();

    const response = await submitVisit(
      visitPayload(refs, id, [
        {
          taxon: 'Anthus trivialis',
          qualifier: 'cf.',
          specimenCode: 'SP-1',
          determiner: 'A. Determiner',
          date: '2026-04-01',
        },
      ]),
    );

    expect(response.status, await response.clone().text()).toBe(201);

    const rows = await determinationsForVisit(id);
    expect(rows).toHaveLength(1);
    expect(rows[0]!.taxon).toBe('Anthus trivialis');
    expect(rows[0]!.qualifier).toBe('cf.');
    expect(rows[0]!.specimenCode).toBe('SP-1');
    expect(rows[0]!.determiner).toBe('A. Determiner');
    expect(rows[0]!.date).toBe('2026-04-01');
    expect(rows[0]!.replacesId).toBeNull();
  });

  it('links a revised Determination to the one it replaces and never overwrites it', async () => {
    const refs = await seedReferences();
    const id = uuidv7();

    const response = await submitVisit(
      visitPayload(refs, id, [
        {
          taxon: 'Anthus trivialis',
          qualifier: 'cf.',
          determiner: 'A. Determiner',
          date: '2026-04-01',
        },
        {
          taxon: 'Anthus pratensis',
          qualifier: 'aff.',
          determiner: 'B. Determiner',
          date: '2026-04-02',
          replacesIndex: 0,
        },
      ]),
    );

    expect(response.status, await response.clone().text()).toBe(201);

    const rows = await determinationsForVisit(id);
    expect(rows).toHaveLength(2);
    const original = rows.find((row) => row.taxon === 'Anthus trivialis')!;
    const revision = rows.find((row) => row.taxon === 'Anthus pratensis')!;
    expect(original.replacesId).toBeNull();
    expect(original.qualifier).toBe('cf.');
    expect(revision.replacesId).toBe(original.id);
    expect(revision.id).not.toBe(original.id);
  });

  it('rejects a Determination whose replacesIndex names no stored Determination', async () => {
    const refs = await seedReferences();
    const id = uuidv7();

    const response = await submitVisit(
      visitPayload(refs, id, [
        {
          taxon: 'Anthus trivialis',
          determiner: 'A. Determiner',
          date: '2026-04-01',
          replacesIndex: 0,
        },
      ]),
    );

    expect(response.status).toBe(400);
    expect(await determinationsForVisit(id)).toHaveLength(0);
  });
});
