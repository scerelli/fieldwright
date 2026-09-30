import { spawnSync } from 'node:child_process';
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
import { surveyPeriod } from '../src/db/schema.js';
import { ProjectsModule } from '../src/projects/projects.module.js';
import { ProjectsService } from '../src/projects/projects.service.js';
import { SurveyPeriodsModule } from '../src/survey-periods/survey-periods.module.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const CREATOR_EMAIL = 'survey-period-creator@example.com';
const COLLECTOR_EMAIL = 'survey-period-collector@example.com';
const PASSWORD = 'correct-horse-battery-staple';

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

@Module({
  imports: [SurveyPeriodsModule, ProjectsModule, AuthModule, DatabaseModule],
})
class TestModule {}

describe('Survey periods', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;
  let app: INestApplication;
  let baseUrl: string;
  let creatorId: string;
  let creatorCookie: string;
  let collectorCookie: string;

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

    const creator = await signUpAndSignIn(CREATOR_EMAIL);
    creatorId = creator.id;
    creatorCookie = creator.cookie;
    collectorCookie = (await signUpAndSignIn(COLLECTOR_EMAIL)).cookie;
  }, 180_000);

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await container?.stop();
  });

  async function signUpAndSignIn(
    email: string,
  ): Promise<{ id: string; cookie: string }> {
    const signUp = await fetch(`${baseUrl}/api/auth/sign-up/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: PASSWORD, name: 'S' }),
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

  async function newProject(): Promise<string> {
    const projects = app.get(ProjectsService);
    const project = await projects.create(creatorId, {
      name: 'River survey',
      validationEnabled: true,
      sensitiveTaxaObfuscation: false,
      taxonomicReferenceId: 'italy-vascular-flora',
      taxonomicReferenceVersion: '2024.1',
    });
    return project.id;
  }

  async function addCollector(projectId: string): Promise<void> {
    await app.get(ProjectsService).addMember(creatorId, projectId, {
      email: COLLECTOR_EMAIL,
      role: 'collector',
    });
  }

  function createSurveyPeriod(
    body: unknown,
    headers: Record<string, string> = {},
  ) {
    return fetch(`${baseUrl}/survey-periods`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: JSON.stringify(body),
    });
  }

  function listSurveyPeriods(
    projectId: string,
    headers: Record<string, string> = {},
  ) {
    return fetch(`${baseUrl}/survey-periods?projectId=${projectId}`, {
      headers,
    });
  }

  const range = { startDate: '2026-03-01', endDate: '2026-05-31' };

  it('stores a Survey period with a name and a date range for the creator', async () => {
    const projectId = await newProject();

    const response = await createSurveyPeriod(
      { projectId, name: 'Spring survey', ...range },
      { cookie: creatorCookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      id: string;
      projectId: string;
      name: string;
      startDate: string;
      endDate: string;
    };
    expect(body.projectId).toBe(projectId);
    expect(body.name).toBe('Spring survey');
    expect(body.startDate).toBe(range.startDate);
    expect(body.endDate).toBe(range.endDate);

    const db = app.get<NodePgDatabase>(DATABASE);
    const rows = await db
      .select()
      .from(surveyPeriod)
      .where(eq(surveyPeriod.id, body.id));
    expect(rows).toHaveLength(1);
    expect(rows[0]!.projectId).toBe(projectId);
    expect(rows[0]!.startDate).toBe(range.startDate);
    expect(rows[0]!.endDate).toBe(range.endDate);
  });

  it('rejects a Survey period whose end precedes its start and stores nothing', async () => {
    const projectId = await newProject();
    const db = app.get<NodePgDatabase>(DATABASE);
    const before = await db.select().from(surveyPeriod);

    const response = await createSurveyPeriod(
      {
        projectId,
        name: 'Backwards survey',
        startDate: '2026-05-31',
        endDate: '2026-03-01',
      },
      { cookie: creatorCookie },
    );

    expect(response.status).toBe(400);
    expect(await db.select().from(surveyPeriod)).toHaveLength(before.length);
  });

  it('accepts a single-day Survey period where end equals start', async () => {
    const projectId = await newProject();

    const response = await createSurveyPeriod(
      {
        projectId,
        name: 'One-day survey',
        startDate: '2026-06-01',
        endDate: '2026-06-01',
      },
      { cookie: creatorCookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
  });

  it('rejects an end-date-before-start-date row at the database constraint', async () => {
    const projectId = await newProject();
    const db = app.get<NodePgDatabase>(DATABASE);

    await expect(
      db.insert(surveyPeriod).values({
        projectId,
        name: 'Invalid direct insert',
        startDate: '2026-07-01',
        endDate: '2026-06-01',
      }),
    ).rejects.toThrow();
  });

  it('belongs to exactly one Project and lists only that Project', async () => {
    const projectA = await newProject();
    const projectB = await newProject();

    const created = await createSurveyPeriod(
      { projectId: projectA, name: 'Project A period', ...range },
      { cookie: creatorCookie },
    );
    const body = (await created.json()) as { id: string; projectId: string };
    expect(body.projectId).toBe(projectA);

    const listedA = await listSurveyPeriods(projectA, {
      cookie: creatorCookie,
    });
    expect(listedA.status, await listedA.clone().text()).toBe(200);
    const rowsA = (await listedA.json()) as Array<{ id: string }>;
    expect(rowsA.map((row) => row.id)).toContain(body.id);

    const listedB = await listSurveyPeriods(projectB, {
      cookie: creatorCookie,
    });
    expect(listedB.status, await listedB.clone().text()).toBe(200);
    const rowsB = (await listedB.json()) as Array<{ id: string }>;
    expect(rowsB.map((row) => row.id)).not.toContain(body.id);
  });

  it('rejects an unauthenticated create with 401', async () => {
    const projectId = await newProject();

    const response = await createSurveyPeriod({
      projectId,
      name: 'No auth',
      ...range,
    });

    expect(response.status).toBe(401);
  });

  it('rejects a non-creator member creating with 403 and stores nothing', async () => {
    const projectId = await newProject();
    await addCollector(projectId);
    const db = app.get<NodePgDatabase>(DATABASE);
    const before = await db.select().from(surveyPeriod);

    const response = await createSurveyPeriod(
      { projectId, name: 'Collector attempt', ...range },
      { cookie: collectorCookie },
    );

    expect(response.status).toBe(403);
    expect(await db.select().from(surveyPeriod)).toHaveLength(before.length);
  });

  it('rejects listing a Project the person is not a member of with 404', async () => {
    const projectId = await newProject();

    const response = await listSurveyPeriods(projectId, {
      cookie: collectorCookie,
    });

    expect(response.status).toBe(404);
  });
});
