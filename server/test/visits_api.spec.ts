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
import { eq, sql } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AuthModule } from '../src/auth/auth.module.js';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import {
  detection,
  membership,
  project,
  protocolVersion,
  site,
  surveyPeriod,
  visit,
  type ProjectSettings,
} from '../src/db/schema.js';
import { VisitsModule } from '../src/visits/visits.module.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const EMAIL = 'collector@example.com';
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
  taxonomicReferenceId: string;
  taxonomicReferenceVersion: string;
}

describe('POST /api/v1/visits', () => {
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

    const collector = await signUpAndSignIn(EMAIL);
    cookie = collector.cookie;
  }, 180_000);

  async function signUpAndSignIn(
    email: string,
  ): Promise<{ id: string; cookie: string }> {
    const signUp = await fetch(`${baseUrl}/api/auth/sign-up/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: PASSWORD, name: 'V' }),
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
      .find((value) => value.includes('better-auth.session_token')); // glossary:allow Better Auth's auth-session cookie, not the Visit
    if (token === undefined) {
      throw new Error('sign-in returned no auth cookie');
    }
    return { id: signedIn.user.id, cookie: token.split(';')[0]! };
  }

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await container?.stop();
  });

  async function seedReferences(
    requiredEffortFields?: string[],
    targetList?: Array<{ taxonRef: string }>,
    taxonomicReference: { id: string; version: string } = {
      id: 'italy-vascular-flora',
      version: '2024.1',
    },
    settings: ProjectSettings = {
      validationEnabled: true,
      sensitiveTaxaObfuscation: false,
    }
  ): Promise<SeedReferences> {
    const [createdProject] = await db
      .insert(project)
      .values({
        name: 'Visit API project',
        settings,
        taxonomicReferenceId: taxonomicReference.id,
        taxonomicReferenceVersion: taxonomicReference.version,
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
        document: {
          protocolId: 'standard',
          version: 1,
          ...(requiredEffortFields === undefined
            ? {}
            : { requiredEffortFields }),
          ...(targetList === undefined ? {} : { targetList }),
        },
      })
      .returning();

    return {
      projectId: createdProject.id,
      siteId: createdSite.id,
      surveyPeriodId: createdPeriod.id,
      protocolVersionId: createdProtocol.id,
      taxonomicReferenceId: createdProject.taxonomicReferenceId,
      taxonomicReferenceVersion: createdProject.taxonomicReferenceVersion,
    };
  }

  function validPayload(refs: SeedReferences, id: string) {
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
          count: 3,
        },
      ],
    };
  }

  function submitVisit(body: unknown, headers: Record<string, string> = {}) {
    return fetch(`${baseUrl}/api/v1/visits`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: JSON.stringify(body),
    });
  }

  function postValidation(
    visitId: string,
    body: unknown,
    headers: Record<string, string> = {},
  ) {
    return fetch(`${baseUrl}/api/v1/visits/${visitId}/validation`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: JSON.stringify(body),
    });
  }

  async function addMembership(
    personId: string,
    projectId: string,
    role: 'creator' | 'collector' | 'validator',
  ): Promise<void> {
    await db.insert(membership).values({ personId, projectId, role });
  }

  /** A stored Visit in the given state, for the Validation transition. */
  async function seedVisit(
    refs: SeedReferences,
    state: 'submitted' | 'validated' | 'rejected' = 'submitted',
  ): Promise<string> {
    const id = uuidv7();
    await db.insert(visit).values({
      id,
      projectId: refs.projectId,
      siteId: refs.siteId,
      surveyPeriodId: refs.surveyPeriodId,
      protocolVersionId: refs.protocolVersionId,
      taxonomicReferenceId: refs.taxonomicReferenceId,
      taxonomicReferenceVersion: refs.taxonomicReferenceVersion,
      state,
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      submittedAt: new Date('2026-04-01T09:05:00Z'),
    });
    return id;
  }

  it('stores exactly one Visit for a valid payload', async () => {
    const refs = await seedReferences();
    const id = uuidv7();

    const response = await submitVisit(validPayload(refs, id), { cookie });

    expect(response.status, await response.clone().text()).toBe(201);
    const rows = await db.select().from(visit).where(eq(visit.id, id));
    expect(rows).toHaveLength(1);
    expect(rows[0]!.state).toBe('submitted');
    expect(rows[0]!.siteId).toBe(refs.siteId);

    const detections = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    expect(detections).toHaveLength(1);
  });

  it('stores the Project’s pinned Taxonomic reference id and version with the submitted Visit', async () => {
    const reference = { id: 'fauna-italiae', version: '2025.2' };
    const refs = await seedReferences(undefined, undefined, reference);
    const id = uuidv7();

    const response = await submitVisit(validPayload(refs, id), { cookie });

    expect(response.status, await response.clone().text()).toBe(201);
    const [stored] = await db.select().from(visit).where(eq(visit.id, id));
    expect(stored!.taxonomicReferenceId).toBe(reference.id);
    expect(stored!.taxonomicReferenceVersion).toBe(reference.version);
  });

  it('rejects a Visit row with no recorded Taxonomic reference id or version at the database', async () => {
    const refs = await seedReferences();
    const id = uuidv7();

    await expect(
      db.execute(sql`
        insert into visit
          (id, project_id, site_id, survey_period_id, protocol_version_id, state, effort, started_at, submitted_at)
        values
          (${id}, ${refs.projectId}, ${refs.siteId}, ${refs.surveyPeriodId}, ${refs.protocolVersionId}, 'submitted', '{}'::jsonb, now(), now())
      `),
    ).rejects.toThrow();

    await expect(
      db.execute(sql`
        insert into visit
          (id, project_id, site_id, survey_period_id, protocol_version_id, state, effort, started_at, submitted_at, taxonomic_reference_id)
        values
          (${uuidv7()}, ${refs.projectId}, ${refs.siteId}, ${refs.surveyPeriodId}, ${refs.protocolVersionId}, 'submitted', '{}'::jsonb, now(), now(), 'italy-vascular-flora')
      `),
    ).rejects.toThrow();

    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
  });

  it('stores exactly one Visit when the same UUIDv7 is submitted twice', async () => {
    const refs = await seedReferences();
    const id = uuidv7();

    const first = await submitVisit(validPayload(refs, id), { cookie });
    const second = await submitVisit(validPayload(refs, id), { cookie });

    expect(first.status, await first.clone().text()).toBe(201);
    expect(second.status, await second.clone().text()).toBe(201);
    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      1,
    );
  });

  it('ignores unknown fields', async () => {
    const refs = await seedReferences();
    const id = uuidv7();

    const response = await submitVisit(
      { ...validPayload(refs, id), unexpected: 'ignored' },
      { cookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      1,
    );
  });

  it('rejects a payload missing a required field with 400 and stores nothing', async () => {
    const refs = await seedReferences();
    const id = uuidv7();
    const payload: Partial<ReturnType<typeof validPayload>> = {
      ...validPayload(refs, id),
    };
    delete payload.siteId;

    const response = await submitVisit(payload, { cookie });

    expect(response.status).toBe(400);
    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
  });

  it('rejects a Sampling effort that omits a field the Protocol version requires with 400 and stores no Visit', async () => {
    const refs = await seedReferences([
      'start',
      'duration',
      'observers',
      'detectionMethods',
    ]);
    const id = uuidv7();

    const response = await submitVisit(
      {
        ...validPayload(refs, id),
        effort: {
          start: '2026-04-01T08:00:00Z',
          duration: 60,
          observers: ['A. Collector'],
        },
      },
      { cookie },
    );

    expect(response.status, await response.clone().text()).toBe(400);
    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
  });

  it('stores a submitted Visit when every required Sampling-effort field is recorded', async () => {
    const refs = await seedReferences([
      'start',
      'duration',
      'observers',
      'detectionMethods',
    ]);
    const id = uuidv7();
    const effort = {
      start: '2026-04-01T08:00:00Z',
      duration: 60,
      observers: ['A. Collector'],
      detectionMethods: ['visual'],
    };

    const response = await submitVisit(
      { ...validPayload(refs, id), effort },
      { cookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const rows = await db.select().from(visit).where(eq(visit.id, id));
    expect(rows).toHaveLength(1);
    expect(rows[0]!.state).toBe('submitted');
    expect(rows[0]!.effort).toMatchObject(effort);
  });

  it('rejects a submission with no Detection for a target taxon with 400 and stores no Visit', async () => {
    const refs = await seedReferences(undefined, [
      { taxonRef: 'Anthus trivialis' },
      { taxonRef: 'Sylvia borin' },
    ]);
    const id = uuidv7();

    const response = await submitVisit(validPayload(refs, id), { cookie });

    expect(response.status, await response.clone().text()).toBe(400);
    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
  });

  it('accepts a target taxon whose Detection has detected = false, recording a non-detection', async () => {
    const refs = await seedReferences(undefined, [
      { taxonRef: 'Sylvia borin' },
    ]);
    const id = uuidv7();

    const response = await submitVisit(
      {
        ...validPayload(refs, id),
        detections: [
          { taxon: 'Sylvia borin', detected: false, method: 'audio' },
        ],
      },
      { cookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const detections = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    const nonDetection = detections.find(
      (row) => row.taxon === 'Sylvia borin',
    );
    expect(nonDetection?.detected).toBe(false);
  });

  it('rejects a submission whose only Detection for a target taxon is opportunistic with 400 and stores no Visit', async () => {
    const refs = await seedReferences(undefined, [
      { taxonRef: 'Vulpes vulpes' },
    ]);
    const id = uuidv7();

    const response = await submitVisit(
      {
        ...validPayload(refs, id),
        detections: [
          {
            taxon: 'Vulpes vulpes',
            detected: true,
            method: 'visual',
            opportunistic: true,
          },
        ],
      },
      { cookie },
    );

    expect(response.status, await response.clone().text()).toBe(400);
    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
  });

  it('rejects an unauthenticated request with 401', async () => {
    const refs = await seedReferences();
    const id = uuidv7();

    const response = await submitVisit(validPayload(refs, id));

    expect(response.status).toBe(401);
  });

  it('validates a submitted Visit, recording the validator and the time', async () => {
    const refs = await seedReferences();
    const validator = await signUpAndSignIn('visit-validator@example.com');
    await addMembership(validator.id, refs.projectId, 'validator');
    const id = await seedVisit(refs);

    const response = await postValidation(
      id,
      { state: 'validated' },
      { cookie: validator.cookie },
    );

    expect(response.status, await response.clone().text()).toBe(200);
    const [row] = await db.select().from(visit).where(eq(visit.id, id));
    expect(row!.state).toBe('validated');
    expect(row!.validatorId).toBe(validator.id);
    expect(row!.validatedAt).not.toBeNull();
  });

  it('rejects a submitted Visit and changes no other column', async () => {
    const refs = await seedReferences();
    const validator = await signUpAndSignIn('visit-rejector@example.com');
    await addMembership(validator.id, refs.projectId, 'validator');
    const id = await seedVisit(refs);
    const [before] = await db.select().from(visit).where(eq(visit.id, id));

    const response = await postValidation(
      id,
      { state: 'rejected' },
      { cookie: validator.cookie },
    );

    expect(response.status, await response.clone().text()).toBe(200);
    const [after] = await db.select().from(visit).where(eq(visit.id, id));
    expect(after!.state).toBe('rejected');
    expect(after!.validatorId).toBe(validator.id);
    expect(after!.validatedAt).not.toBeNull();

    const changed = new Set(['state', 'validatorId', 'validatedAt']);
    const beforeFields = before as unknown as Record<string, unknown>;
    const afterFields = after as unknown as Record<string, unknown>;
    for (const key of Object.keys(beforeFields)) {
      if (!changed.has(key)) {
        expect(afterFields[key], key).toEqual(beforeFields[key]);
      }
    }
  });

  it('refuses a validation when the Project has validation disabled, leaving the Visit unchanged', async () => {
    const refs = await seedReferences(undefined, undefined, undefined, {
      validationEnabled: false,
      sensitiveTaxaObfuscation: false,
    });
    const validator = await signUpAndSignIn('visit-disabled@example.com');
    await addMembership(validator.id, refs.projectId, 'validator');
    const id = await seedVisit(refs);
    const [before] = await db.select().from(visit).where(eq(visit.id, id));

    const response = await postValidation(
      id,
      { state: 'validated' },
      { cookie: validator.cookie },
    );

    expect(response.status, await response.clone().text()).toBe(409);
    const [after] = await db.select().from(visit).where(eq(visit.id, id));
    expect(after).toEqual(before);
  });

  it('refuses a validation of a Visit that is not submitted, leaving it unchanged', async () => {
    const refs = await seedReferences();
    const validator = await signUpAndSignIn('visit-not-submitted@example.com');
    await addMembership(validator.id, refs.projectId, 'validator');
    const id = await seedVisit(refs, 'validated');
    const [before] = await db.select().from(visit).where(eq(visit.id, id));

    const response = await postValidation(
      id,
      { state: 'rejected' },
      { cookie: validator.cookie },
    );

    expect(response.status, await response.clone().text()).toBe(409);
    const [after] = await db.select().from(visit).where(eq(visit.id, id));
    expect(after).toEqual(before);
  });

  it('refuses a person without the validator Membership with 403, leaving the Visit unchanged', async () => {
    const refs = await seedReferences();
    const collector = await signUpAndSignIn('visit-collector@example.com');
    await addMembership(collector.id, refs.projectId, 'collector');
    const id = await seedVisit(refs);
    const [before] = await db.select().from(visit).where(eq(visit.id, id));

    const response = await postValidation(
      id,
      { state: 'validated' },
      { cookie: collector.cookie },
    );

    expect(response.status).toBe(403);
    const [after] = await db.select().from(visit).where(eq(visit.id, id));
    expect(after).toEqual(before);
  });

  it('refuses an outcome that is not validated or rejected with 400, leaving the Visit unchanged', async () => {
    const refs = await seedReferences();
    const validator = await signUpAndSignIn('visit-bad-outcome@example.com');
    await addMembership(validator.id, refs.projectId, 'validator');
    const id = await seedVisit(refs);
    const [before] = await db.select().from(visit).where(eq(visit.id, id));

    const response = await postValidation(
      id,
      { state: 'in_progress' },
      { cookie: validator.cookie },
    );

    expect(response.status).toBe(400);
    const [after] = await db.select().from(visit).where(eq(visit.id, id));
    expect(after).toEqual(before);
  });

  it('rejects an unauthenticated validation request with 401', async () => {
    const refs = await seedReferences();
    const id = await seedVisit(refs);

    const response = await postValidation(id, { state: 'validated' });

    expect(response.status).toBe(401);
  });
});
