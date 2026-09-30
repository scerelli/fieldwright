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
import { protocolVersion } from '../src/db/schema.js';
import { ProjectsModule } from '../src/projects/projects.module.js';
import { ProjectsService } from '../src/projects/projects.service.js';
import { ProtocolVersionsModule } from '../src/protocol-versions/protocol-versions.module.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const EMAIL = 'protocol-creator@example.com';
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

const completeListDocument = {
  protocolId: 'wetland-plants-2026',
  taxonomicScope: { taxa: ['Tracheophyta'] },
  detectionMethods: [{ id: 'visual', label: 'Visual detection' }],
  requiredEffortFields: ['start', 'duration', 'observers'],
};

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

@Module({
  imports: [ProtocolVersionsModule, ProjectsModule, AuthModule, DatabaseModule],
})
class TestModule {}

describe('Protocol versions', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;
  let app: INestApplication;
  let baseUrl: string;
  let cookie: string;
  let personId: string;

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

    const signUp = await fetch(`${baseUrl}/api/auth/sign-up/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: EMAIL, password: PASSWORD, name: 'C' }),
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

    const signedIn = (await signIn.json()) as { user: { id: string } };
    personId = signedIn.user.id;

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

  async function newProject(): Promise<string> {
    const projects = app.get(ProjectsService);
    const project = await projects.create(personId, {
      name: 'River survey',
      validationEnabled: true,
      sensitiveTaxaObfuscation: false,
      taxonomicReferenceId: 'italy-vascular-flora',
      taxonomicReferenceVersion: '2024.1',
    });
    return project.id;
  }

  function createProtocolVersion(
    projectId: string,
    document: unknown,
    headers: Record<string, string> = {},
  ) {
    return fetch(`${baseUrl}/protocol-versions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: JSON.stringify({ projectId, document }),
    });
  }

  function freezeProtocolVersion(
    id: string,
    headers: Record<string, string> = {},
  ) {
    return fetch(`${baseUrl}/protocol-versions/${id}/freeze`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
    });
  }

  it('stores a schema-valid protocol document with the first version number', async () => {
    const projectId = await newProject();

    const response = await createProtocolVersion(projectId, validDocument, {
      cookie,
    });

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      id: string;
      projectId: string;
      protocolId: string;
      version: number;
      document: Record<string, unknown>;
      frozenAt: string | null;
    };

    expect(body.projectId).toBe(projectId);
    expect(body.protocolId).toBe(validDocument.protocolId);
    expect(body.version).toBe(1);
    expect(body.frozenAt).toBeNull();
    expect(body.document).toEqual({ ...validDocument, version: 1 });

    const db = app.get<NodePgDatabase>(DATABASE);
    const rows = await db
      .select()
      .from(protocolVersion)
      .where(eq(protocolVersion.id, body.id));

    expect(rows).toHaveLength(1);
    expect(rows[0]!.version).toBe(1);
    expect(rows[0]!.document).toEqual({ ...validDocument, version: 1 });
  });

  it('stores a complete-list protocol document with no target list', async () => {
    const projectId = await newProject();

    const response = await createProtocolVersion(
      projectId,
      completeListDocument,
      { cookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      version: number;
      document: Record<string, unknown>;
    };
    expect(body.version).toBe(1);
    expect(body.document).toEqual({ ...completeListDocument, version: 1 });
    expect(body.document.targetList).toBeUndefined();
  });

  it('rejects a document that fails the protocol schema and stores nothing', async () => {
    const projectId = await newProject();
    const db = app.get<NodePgDatabase>(DATABASE);
    const before = await db.select().from(protocolVersion);

    const invalid = { ...validDocument, detectionMethods: [] };
    const response = await createProtocolVersion(projectId, invalid, {
      cookie,
    });
    expect(response.status).toBe(400);

    const withoutProtocolId = { ...validDocument };
    delete (withoutProtocolId as Record<string, unknown>).protocolId;
    const missingId = await createProtocolVersion(
      projectId,
      withoutProtocolId,
      {
        cookie,
      },
    );
    expect(missingId.status).toBe(400);

    expect(await db.select().from(protocolVersion)).toHaveLength(before.length);
  });

  it('rejects an unauthenticated request', async () => {
    const projectId = await newProject();
    const response = await createProtocolVersion(projectId, validDocument);
    expect(response.status).toBe(401);
  });

  it('rejects a project the person is not a member of and stores nothing', async () => {
    const db = app.get<NodePgDatabase>(DATABASE);
    const before = await db.select().from(protocolVersion);

    const response = await createProtocolVersion(
      '00000000-0000-7000-8000-000000000000',
      validDocument,
      { cookie },
    );

    expect(response.status).toBe(404);
    expect(await db.select().from(protocolVersion)).toHaveLength(before.length);
  });

  it('freezes a version and keeps it immutable while a change creates a new version', async () => {
    const projectId = await newProject();

    const created = await createProtocolVersion(projectId, validDocument, {
      cookie,
    });
    const first = (await created.json()) as { id: string; version: number };

    const frozen = await freezeProtocolVersion(first.id, { cookie });
    expect(frozen.status, await frozen.clone().text()).toBe(200);
    const frozenBody = (await frozen.json()) as { frozenAt: string | null };
    expect(frozenBody.frozenAt).not.toBeNull();

    const refrozen = await freezeProtocolVersion(first.id, { cookie });
    expect(refrozen.status).toBe(200);
    const refrozenBody = (await refrozen.json()) as { frozenAt: string | null };
    expect(refrozenBody.frozenAt).toBe(frozenBody.frozenAt);

    const db = app.get<NodePgDatabase>(DATABASE);
    const firstBefore = await db
      .select()
      .from(protocolVersion)
      .where(eq(protocolVersion.id, first.id));

    const changed = {
      ...validDocument,
      detectionMethods: [{ id: 'visual', label: 'Visual detection' }],
    };
    const second = await createProtocolVersion(projectId, changed, { cookie });
    expect(second.status, await second.clone().text()).toBe(201);
    const secondBody = (await second.json()) as { id: string; version: number };
    expect(secondBody.version).toBe(2);

    const firstAfter = await db
      .select()
      .from(protocolVersion)
      .where(eq(protocolVersion.id, first.id));

    expect(firstAfter).toHaveLength(1);
    expect(firstAfter[0]!.document).toEqual(firstBefore[0]!.document);
    expect(firstAfter[0]!.frozenAt).toEqual(firstBefore[0]!.frozenAt);
  });

  it('rejects freezing a version that does not exist', async () => {
    const response = await freezeProtocolVersion(
      '00000000-0000-7000-8000-000000000001',
      { cookie },
    );
    expect(response.status).toBe(404);
  });

  it('rejects changing a frozen version and allows creating a new version', async () => {
    const projectId = await newProject();

    const created = await createProtocolVersion(projectId, validDocument, {
      cookie,
    });
    const first = (await created.json()) as { id: string; version: number };
    await freezeProtocolVersion(first.id, { cookie });

    const rejectedChange = await fetch(
      `${baseUrl}/protocol-versions/${first.id}`,
      {
        method: 'PATCH',
        headers: { 'content-type': 'application/json', cookie },
        body: JSON.stringify({ document: validDocument }),
      },
    );
    expect(rejectedChange.status).toBe(404);

    const next = await createProtocolVersion(projectId, validDocument, {
      cookie,
    });
    expect(next.status, await next.clone().text()).toBe(201);
    const nextBody = (await next.json()) as { version: number };
    expect(nextBody.version).toBe(2);
  });
});
