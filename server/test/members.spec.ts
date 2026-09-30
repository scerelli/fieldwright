import { spawnSync } from 'node:child_process';
import type { AddressInfo } from 'node:net';
import { fileURLToPath } from 'node:url';
import { Module, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { and, eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AuthModule } from '../src/auth/auth.module.js';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import { membership, user } from '../src/db/schema.js';
import { ProjectsModule } from '../src/projects/projects.module.js';
import { ProjectsService } from '../src/projects/projects.service.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const CREATOR_EMAIL = 'members-creator@example.com';
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

describe('Project members', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;
  let app: INestApplication;
  let baseUrl: string;
  let creatorId: string;
  let creatorCookie: string;

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
      body: JSON.stringify({ email, password: PASSWORD, name: 'M' }),
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
    const created = await projects.create(creatorId, {
      name: 'River survey',
      validationEnabled: true,
      sensitiveTaxaObfuscation: false,
      taxonomicReferenceId: 'italy-vascular-flora',
      taxonomicReferenceVersion: '2024.1',
    });
    return created.id;
  }

  function addMember(
    projectId: string,
    body: unknown,
    headers: Record<string, string> = {},
  ) {
    return fetch(`${baseUrl}/projects/${projectId}/members`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: JSON.stringify(body),
    });
  }

  function listMembers(
    projectId: string,
    headers: Record<string, string> = {},
  ) {
    return fetch(`${baseUrl}/projects/${projectId}/members`, { headers });
  }

  it('lets the creator add an existing person as a collector', async () => {
    const projectId = await newProject();
    const target = await signUpAndSignIn('member-collector@example.com');

    const response = await addMember(
      projectId,
      { email: 'member-collector@example.com', role: 'collector' },
      { cookie: creatorCookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      id: string;
      personId: string;
      projectId: string;
      role: string;
    };
    expect(body.personId).toBe(target.id);
    expect(body.projectId).toBe(projectId);
    expect(body.role).toBe('collector');

    const db = app.get<NodePgDatabase>(DATABASE);
    const rows = await db
      .select()
      .from(membership)
      .where(eq(membership.id, body.id));
    expect(rows).toHaveLength(1);
    expect(rows[0]!.personId).toBe(target.id);
    expect(rows[0]!.role).toBe('collector');
  });

  it('lets the creator add an existing person as a validator', async () => {
    const projectId = await newProject();
    const target = await signUpAndSignIn('member-validator@example.com');

    const response = await addMember(
      projectId,
      { email: 'member-validator@example.com', role: 'validator' },
      { cookie: creatorCookie },
    );

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as { personId: string; role: string };
    expect(body.personId).toBe(target.id);
    expect(body.role).toBe('validator');
  });

  it('rejects adding an existing member with 409 and creates no second row', async () => {
    const projectId = await newProject();
    const target = await signUpAndSignIn('member-duplicate@example.com');
    const db = app.get<NodePgDatabase>(DATABASE);

    const first = await addMember(
      projectId,
      { email: 'member-duplicate@example.com', role: 'collector' },
      { cookie: creatorCookie },
    );
    expect(first.status, await first.clone().text()).toBe(201);

    const second = await addMember(
      projectId,
      { email: 'member-duplicate@example.com', role: 'collector' },
      { cookie: creatorCookie },
    );
    expect(second.status, await second.clone().text()).toBe(409);

    const rows = await db
      .select()
      .from(membership)
      .where(
        and(
          eq(membership.projectId, projectId),
          eq(membership.personId, target.id),
        ),
      );
    expect(rows).toHaveLength(1);
  });

  it('lists each person once after a repeated add', async () => {
    const projectId = await newProject();
    const target = await signUpAndSignIn('member-once@example.com');

    await addMember(
      projectId,
      { email: 'member-once@example.com', role: 'collector' },
      { cookie: creatorCookie },
    );
    await addMember(
      projectId,
      { email: 'member-once@example.com', role: 'collector' },
      { cookie: creatorCookie },
    );

    const response = await listMembers(projectId, { cookie: creatorCookie });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as Array<{ personId: string }>;
    expect(body.filter((row) => row.personId === target.id)).toHaveLength(1);
  });

  it('rejects a non-creator member with 403 and stores nothing', async () => {
    const projectId = await newProject();
    const db = app.get<NodePgDatabase>(DATABASE);
    const collector = await signUpAndSignIn('member-not-creator@example.com');
    await db.insert(membership).values({
      personId: collector.id,
      projectId,
      role: 'collector',
    });
    await signUpAndSignIn('member-target-1@example.com');
    const before = await db
      .select()
      .from(membership)
      .where(eq(membership.projectId, projectId));

    const response = await addMember(
      projectId,
      { email: 'member-target-1@example.com', role: 'collector' },
      { cookie: collector.cookie },
    );

    expect(response.status).toBe(403);
    expect(
      await db
        .select()
        .from(membership)
        .where(eq(membership.projectId, projectId)),
    ).toHaveLength(before.length);
  });

  it('rejects a non-member with 403 (no self-granted roles)', async () => {
    const projectId = await newProject();
    const outsider = await signUpAndSignIn('member-outsider@example.com');
    await signUpAndSignIn('member-target-2@example.com');

    const response = await addMember(
      projectId,
      { email: 'member-target-2@example.com', role: 'validator' },
      { cookie: outsider.cookie },
    );

    expect(response.status).toBe(403);
  });

  it('rejects granting the creator role with 400 and stores nothing', async () => {
    const projectId = await newProject();
    const db = app.get<NodePgDatabase>(DATABASE);
    await signUpAndSignIn('member-target-3@example.com');
    const before = await db
      .select()
      .from(membership)
      .where(eq(membership.projectId, projectId));

    const response = await addMember(
      projectId,
      { email: 'member-target-3@example.com', role: 'creator' },
      { cookie: creatorCookie },
    );

    expect(response.status).toBe(400);
    expect(
      await db
        .select()
        .from(membership)
        .where(eq(membership.projectId, projectId)),
    ).toHaveLength(before.length);
  });

  it('rejects an unknown email with 404 and stores nothing', async () => {
    const projectId = await newProject();
    const db = app.get<NodePgDatabase>(DATABASE);
    const before = await db
      .select()
      .from(membership)
      .where(eq(membership.projectId, projectId));

    const response = await addMember(
      projectId,
      { email: 'nobody@example.com', role: 'collector' },
      { cookie: creatorCookie },
    );

    expect(response.status).toBe(404);
    const body = (await response.json()) as { message: string };
    expect(body.message).toBe('person not found');
    expect(
      await db
        .select()
        .from(membership)
        .where(eq(membership.projectId, projectId)),
    ).toHaveLength(before.length);
  });

  it('rejects an unauthenticated request', async () => {
    const projectId = await newProject();
    const [existing] = await app
      .get<NodePgDatabase>(DATABASE)
      .select()
      .from(user)
      .where(eq(user.email, CREATOR_EMAIL));

    const response = await addMember(projectId, {
      email: existing!.email,
      role: 'collector',
    });

    expect(response.status).toBe(401);
  });

  it('lists the project members for a member of that project', async () => {
    const projectId = await newProject();
    const member = await signUpAndSignIn('member-lister@example.com');
    await app.get<NodePgDatabase>(DATABASE).insert(membership).values({
      personId: member.id,
      projectId,
      role: 'collector',
    });

    const response = await listMembers(projectId, { cookie: member.cookie });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as Array<{
      id: string;
      personId: string;
      projectId: string;
      role: string;
      email: string;
    }>;
    expect(body).toHaveLength(2);
    const byPerson = new Map(body.map((row) => [row.personId, row]));
    expect(byPerson.get(creatorId)).toMatchObject({
      projectId,
      role: 'creator',
      email: CREATOR_EMAIL,
    });
    expect(byPerson.get(member.id)).toMatchObject({
      projectId,
      role: 'collector',
      email: 'member-lister@example.com',
    });
  });

  it('lists only the memberships of the requested project', async () => {
    const projectId = await newProject();
    const otherProjectId = await newProject();
    const member = await signUpAndSignIn('member-scoped@example.com');
    await app.get<NodePgDatabase>(DATABASE).insert(membership).values({
      personId: member.id,
      projectId: otherProjectId,
      role: 'validator',
    });

    const response = await listMembers(projectId, { cookie: creatorCookie });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as Array<{
      personId: string;
      role: string;
    }>;
    expect(body).toHaveLength(1);
    expect(body[0]!.personId).toBe(creatorId);
  });

  it('rejects listing members for a non-member with 403', async () => {
    const projectId = await newProject();
    const outsider = await signUpAndSignIn('member-list-outsider@example.com');

    const response = await listMembers(projectId, { cookie: outsider.cookie });

    expect(response.status).toBe(403);
  });

  it('rejects listing members when unauthenticated with 401', async () => {
    const projectId = await newProject();

    const response = await listMembers(projectId);

    expect(response.status).toBe(401);
  });
});
