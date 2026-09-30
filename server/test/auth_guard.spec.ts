import { spawnSync } from 'node:child_process';
import type { AddressInfo } from 'node:net';
import { fileURLToPath } from 'node:url';
import {
  Controller,
  Get,
  Module,
  UseGuards,
  type INestApplication,
} from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AuthGuard, type Person } from '../src/auth/auth.guard.js';
import { AuthModule } from '../src/auth/auth.module.js';
import {
  CurrentMemberships,
  CurrentPerson,
} from '../src/auth/current-person.decorator.js';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import { membership, project, type Membership } from '../src/db/schema.js';

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

@Controller('protected')
class ProtectedController {
  @UseGuards(AuthGuard)
  @Get()
  read(
    @CurrentPerson() person: Person,
    @CurrentMemberships() memberships: Membership[],
  ) {
    return { person, memberships };
  }
}

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [ProtectedController],
})
class ProtectedModule {}

describe('AuthGuard', () => {
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

    app = await NestFactory.create(ProtectedModule, {
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

  function protectedRequest(headers: Record<string, string> = {}) {
    return fetch(`${baseUrl}/protected`, { headers });
  }

  it('returns 401 for an unauthenticated request', async () => {
    const response = await protectedRequest();

    expect(response.status).toBe(401);
  });

  it('exposes the current person for an authenticated request', async () => {
    const response = await protectedRequest({ cookie });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as {
      person: { id: string; email: string };
    };

    expect(body.person.id).toBe(personId);
    expect(body.person.email).toBe(EMAIL);
  });

  it('exposes an empty Membership list when the person has none', async () => {
    const response = await protectedRequest({ cookie });

    const body = (await response.json()) as { memberships: Membership[] };

    expect(body.memberships).toEqual([]);
  });

  it('exposes the current person project Memberships when present', async () => {
    const db = app.get<NodePgDatabase>(DATABASE);
    const [createdProject] = await db
      .insert(project)
      .values({
        name: 'Survey',
        settings: { validationEnabled: false, sensitiveTaxaObfuscation: false },
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
      })
      .returning();
    const projectId = createdProject.id;
    await db.insert(membership).values({
      personId,
      projectId,
      role: 'collector',
    });

    const response = await protectedRequest({ cookie });
    const body = (await response.json()) as {
      memberships: { projectId: string; role: string }[];
    };

    expect(body.memberships).toHaveLength(1);
    expect(body.memberships[0]!.projectId).toBe(projectId);
    expect(body.memberships[0]!.role).toBe('collector');
  });
});
