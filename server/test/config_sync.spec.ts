import { spawnSync } from 'node:child_process';
import type { AddressInfo } from 'node:net';
import { fileURLToPath } from 'node:url';
import { Module, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AuthModule } from '../src/auth/auth.module.js';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import { site } from '../src/db/schema.js';
import { ProjectsModule } from '../src/projects/projects.module.js';
import { ProjectsService } from '../src/projects/projects.service.js';
import { ProtocolVersionsModule } from '../src/protocol-versions/protocol-versions.module.js';
import { SurveyPeriodsModule } from '../src/survey-periods/survey-periods.module.js';
import { SyncModule } from '../src/sync/sync.module.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const MEMBER_EMAIL = 'sync-member@example.com';
const OUTSIDER_EMAIL = 'sync-outsider@example.com';
const PASSWORD = 'correct-horse-battery-staple';

const validDocument = {
  protocolId: 'alpine-birds-2026',
  taxonomicScope: { taxa: ['Aves'] },
  targetList: [
    { taxonRef: 'Aves|Turdus|merula', label: 'Common blackbird' },
    { taxonRef: 'Aves|Erithacus|rubecula', label: 'European robin' },
  ],
  detectionMethods: [
    { id: 'visual', label: 'Visual detection' },
    { id: 'acoustic', label: 'Acoustic detection' },
  ],
  requiredEffortFields: ['start', 'duration', 'observers', 'detectionMethods'],
  visitCovariates: [{ name: 'windSpeed', type: 'number', unit: 'm/s' }],
  siteCovariates: [{ name: 'habitat', type: 'text' }],
};

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

@Module({
  imports: [
    SyncModule,
    ProjectsModule,
    ProtocolVersionsModule,
    SurveyPeriodsModule,
    AuthModule,
    DatabaseModule,
  ],
})
class TestModule {}

interface ConfigPullBody {
  versionToken: string;
  project?: { id: string; description: string | null };
  protocolVersion?: { document: Record<string, unknown> };
  surveyPeriods: unknown[];
  sites: unknown[];
}

describe('GET /api/v1/projects/:projectId/config', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;
  let app: INestApplication;
  let baseUrl: string;
  let memberCookie: string;
  let outsiderCookie: string;
  let memberId: string;
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

    async function signIn(
      email: string,
    ): Promise<{ cookie: string; id: string }> {
      const signUp = await fetch(`${baseUrl}/api/auth/sign-up/email`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ email, password: PASSWORD, name: email }),
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
      const body = (await signIn.json()) as { user: { id: string } };
      const token = signIn.headers
        .getSetCookie()
        .find((value) => value.includes('better-auth.session_token')); // glossary:allow Better Auth's auth-session cookie, not the Visit
      if (token === undefined) {
        throw new Error('sign-in returned no auth cookie');
      }
      return { cookie: token.split(';')[0]!, id: body.user.id };
    }

    const member = await signIn(MEMBER_EMAIL);
    memberCookie = member.cookie;
    memberId = member.id;
    outsiderCookie = (await signIn(OUTSIDER_EMAIL)).cookie;
  }, 180_000);

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await container?.stop();
  });

  async function newProject(description?: string): Promise<string> {
    const project = await app.get(ProjectsService).create(memberId, {
      name: 'River survey',
      description,
      validationEnabled: true,
      sensitiveTaxaObfuscation: false,
      taxonomicReferenceId: 'italy-vascular-flora',
      taxonomicReferenceVersion: '2024.1',
    });
    return project.id;
  }

  function pull(
    projectId: string,
    token: string | undefined,
    options: { cookie?: string; extra?: string } = {},
  ) {
    const params = new URLSearchParams();
    if (token !== undefined) {
      params.set('since', token);
    }
    const extra = options.extra ? `&${options.extra}` : '';
    const url = `${baseUrl}/api/v1/projects/${projectId}/config?${params.toString()}${extra}`;
    return fetch(url, {
      headers: options.cookie ? { cookie: options.cookie } : {},
    });
  }

  function createProtocolVersion(projectId: string) {
    return fetch(`${baseUrl}/protocol-versions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', cookie: memberCookie },
      body: JSON.stringify({ projectId, document: validDocument }),
    });
  }

  function createSurveyPeriod(projectId: string) {
    return fetch(`${baseUrl}/survey-periods`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', cookie: memberCookie },
      body: JSON.stringify({
        projectId,
        name: 'Spring 2026',
        startDate: '2026-03-01',
        endDate: '2026-05-31',
      }),
    });
  }

  async function createSite(projectId: string): Promise<void> {
    await db.insert(site).values({ projectId, name: 'Site A' });
  }

  it('returns an empty change set when the token from the preceding pull is reused', async () => {
    const projectId = await newProject();
    await createProtocolVersion(projectId);
    await createSurveyPeriod(projectId);
    await createSite(projectId);

    const first = await pull(projectId, undefined, { cookie: memberCookie });
    expect(first.status, await first.clone().text()).toBe(200);
    const firstBody = (await first.json()) as ConfigPullBody;
    expect(firstBody.project?.id).toBe(projectId);
    expect(firstBody.protocolVersion?.document.targetList).toBeDefined();
    expect(firstBody.surveyPeriods).toHaveLength(1);
    expect(firstBody.sites).toHaveLength(1);

    const second = await pull(projectId, firstBody.versionToken, {
      cookie: memberCookie,
    });
    expect(second.status, await second.clone().text()).toBe(200);
    const secondBody = (await second.json()) as ConfigPullBody;
    expect(secondBody.project).toBeUndefined();
    expect(secondBody.protocolVersion).toBeUndefined();
    expect(secondBody.surveyPeriods).toEqual([]);
    expect(secondBody.sites).toEqual([]);
    expect(secondBody.versionToken).toBe(firstBody.versionToken);
  });

  it('carries the Project description on a full pull', async () => {
    const projectId = await newProject('A description for the members');

    const response = await pull(projectId, undefined, { cookie: memberCookie });
    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as ConfigPullBody;

    expect(body.project?.description).toBe('A description for the members');
  });

  it('returns a Protocol version created after the token, with a newer token', async () => {
    const projectId = await newProject();
    const before = await pull(projectId, undefined, { cookie: memberCookie });
    const { versionToken } = (await before.json()) as ConfigPullBody;

    await createProtocolVersion(projectId);

    const after = await pull(projectId, versionToken, { cookie: memberCookie });
    expect(after.status, await after.clone().text()).toBe(200);
    const body = (await after.json()) as ConfigPullBody;
    expect(body.protocolVersion?.document.targetList).toBeDefined();
    expect(BigInt(body.versionToken) > BigInt(versionToken)).toBe(true);
  });

  it('returns a Survey period created after the token, with a newer token', async () => {
    const projectId = await newProject();
    const before = await pull(projectId, undefined, { cookie: memberCookie });
    const { versionToken } = (await before.json()) as ConfigPullBody;

    await createSurveyPeriod(projectId);

    const after = await pull(projectId, versionToken, { cookie: memberCookie });
    expect(after.status, await after.clone().text()).toBe(200);
    const body = (await after.json()) as ConfigPullBody;
    expect(body.surveyPeriods).toHaveLength(1);
    expect(BigInt(body.versionToken) > BigInt(versionToken)).toBe(true);
  });

  it('returns a Site created after the token, with a newer token', async () => {
    const projectId = await newProject();
    const before = await pull(projectId, undefined, { cookie: memberCookie });
    const { versionToken } = (await before.json()) as ConfigPullBody;

    await createSite(projectId);

    const after = await pull(projectId, versionToken, { cookie: memberCookie });
    expect(after.status, await after.clone().text()).toBe(200);
    const body = (await after.json()) as ConfigPullBody;
    expect(body.sites).toHaveLength(1);
    expect(BigInt(body.versionToken) > BigInt(versionToken)).toBe(true);
  });

  it('rejects a pull for a project the person is not a member of', async () => {
    const projectId = await newProject();

    const response = await pull(projectId, undefined, {
      cookie: outsiderCookie,
    });

    expect(response.status).toBe(404);
  });

  it('rejects an unauthenticated pull', async () => {
    const projectId = await newProject();

    const response = await pull(projectId, undefined);

    expect(response.status).toBe(401);
  });

  it('accepts and ignores an unknown query parameter', async () => {
    const projectId = await newProject();

    const response = await pull(projectId, undefined, {
      cookie: memberCookie,
      extra: 'unknown=1',
    });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as ConfigPullBody;
    expect(typeof body.versionToken).toBe('string');
  });

  it('serves the config pull under the /api/v1 prefix', async () => {
    const projectId = await newProject();

    const underPrefix = await pull(projectId, undefined, {
      cookie: memberCookie,
    });
    expect(underPrefix.status).toBe(200);

    const withoutPrefix = await fetch(
      `${baseUrl}/projects/${projectId}/config`,
      { headers: { cookie: memberCookie } },
    );
    expect(withoutPrefix.status).toBe(404);
  });
});
