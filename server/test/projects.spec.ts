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
import { membership, project } from '../src/db/schema.js';
import { ProjectsModule } from '../src/projects/projects.module.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const EMAIL = 'creator@example.com';
const PASSWORD = 'correct-horse-battery-staple';

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

@Module({
  imports: [ProjectsModule, AuthModule, DatabaseModule],
})
class TestModule {}

describe('Project creation', () => {
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

  function createProject(body: unknown, headers: Record<string, string> = {}) {
    return fetch(`${baseUrl}/projects`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: JSON.stringify(body),
    });
  }

  const validBody = {
    name: 'River survey',
    validationEnabled: true,
    sensitiveTaxaObfuscation: false,
    taxonomicReferenceId: 'italy-vascular-flora',
    taxonomicReferenceVersion: '2024.1',
  };

  it('stores a project with its settings for an authenticated creator', async () => {
    const response = await createProject(validBody, { cookie });

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      id: string;
      name: string;
      settings: {
        validationEnabled: boolean;
        sensitiveTaxaObfuscation: boolean;
      };
      taxonomicReferenceId: string;
      taxonomicReferenceVersion: string;
    };

    expect(body.id).toBeDefined();
    expect(body.name).toBe(validBody.name);
    expect(body.settings).toEqual({
      validationEnabled: true,
      sensitiveTaxaObfuscation: false,
    });
    expect(body.taxonomicReferenceId).toBe(validBody.taxonomicReferenceId);
    expect(body.taxonomicReferenceVersion).toBe(
      validBody.taxonomicReferenceVersion,
    );

    const db = app.get<NodePgDatabase>(DATABASE);
    const rows = await db.select().from(project).where(eq(project.id, body.id));

    expect(rows).toHaveLength(1);
    expect(rows[0]!.settings).toEqual({
      validationEnabled: true,
      sensitiveTaxaObfuscation: false,
    });
  });

  it('creates a Project from only a name, with no pinned Taxonomic reference', async () => {
    const response = await createProject({ name: 'Only a name' }, { cookie });

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      id: string;
      name: string;
      taxonomicReferenceId: string | null;
      taxonomicReferenceVersion: string | null;
    };

    expect(body.name).toBe('Only a name');
    expect(body.taxonomicReferenceId).toBeNull();
    expect(body.taxonomicReferenceVersion).toBeNull();
  });

  it('stores the default validation and sensitive-taxa obfuscation settings when none are supplied', async () => {
    const response = await createProject(
      { name: 'Defaulted settings' },
      {
        cookie,
      },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      id: string;
      settings: {
        validationEnabled: boolean;
        sensitiveTaxaObfuscation: boolean;
      };
    };

    expect(body.settings).toEqual({
      validationEnabled: false,
      sensitiveTaxaObfuscation: true,
    });

    const db = app.get<NodePgDatabase>(DATABASE);
    const rows = await db.select().from(project).where(eq(project.id, body.id));

    expect(rows).toHaveLength(1);
    expect(rows[0]!.settings).toEqual({
      validationEnabled: false,
      sensitiveTaxaObfuscation: true,
    });
  });

  it('accepts and returns an optional description', async () => {
    const description = 'A shared description for the members';
    const response = await createProject(
      { ...validBody, description },
      { cookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      id: string;
      description: string | null;
    };

    expect(body.description).toBe(description);

    const db = app.get<NodePgDatabase>(DATABASE);
    const rows = await db.select().from(project).where(eq(project.id, body.id));

    expect(rows).toHaveLength(1);
    expect(rows[0]!.description).toBe(description);
  });

  it('returns a null description when none is supplied', async () => {
    const response = await createProject(validBody, { cookie });

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as { description: string | null };

    expect(body.description).toBeNull();
  });

  it('adds the creator as a Membership with role creator', async () => {
    const response = await createProject(validBody, { cookie });
    const body = (await response.json()) as { id: string };

    const db = app.get<NodePgDatabase>(DATABASE);
    const rows = await db
      .select()
      .from(membership)
      .where(eq(membership.projectId, body.id));

    expect(rows).toHaveLength(1);
    expect(rows[0]!.personId).toBe(personId);
    expect(rows[0]!.role).toBe('creator');
  });

  it('rejects invalid settings and stores nothing', async () => {
    const db = app.get<NodePgDatabase>(DATABASE);
    const projectsBefore = await db.select().from(project);
    const membershipsBefore = await db.select().from(membership);

    const response = await createProject(
      { ...validBody, validationEnabled: 'yes' },
      { cookie },
    );

    expect(response.status).toBe(400);

    expect(await db.select().from(project)).toHaveLength(projectsBefore.length);
    expect(await db.select().from(membership)).toHaveLength(
      membershipsBefore.length,
    );
  });

  it('rejects an unauthenticated request', async () => {
    const response = await createProject(validBody);

    expect(response.status).toBe(401);
  });
});
