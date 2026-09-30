import { spawnSync } from 'node:child_process';
import type { AddressInfo } from 'node:net';
import { fileURLToPath } from 'node:url';
import type { INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AuthModule } from '../src/auth/auth.module.js';
import { DATABASE_POOL } from '../src/db/database.provider.js';

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

describe('Better Auth', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;
  let app: INestApplication;
  let baseUrl: string;

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

    app = await NestFactory.create(AuthModule, { logger: false });
    await app.listen(0);
    const address = app.getHttpServer().address() as AddressInfo;
    baseUrl = `http://127.0.0.1:${address.port}`;
  }, 180_000);

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await container?.stop();
  });

  it('creates the better-auth tables on a fresh database', async () => {
    const pool = new Pool({ connectionString: databaseUrl });
    try {
      const { rows } = await pool.query<{ tablename: string }>(
        "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename",
      );
      const tables = rows.map((row) => row.tablename);

      expect(tables).toEqual(
        expect.arrayContaining([
          'account',
          'session', // glossary:allow Better Auth's auth-session table, not the Visit
          'user',
          'verification',
        ]),
      );
    } finally {
      await pool.end();
    }
  });

  it('signs up then signs in and returns an auth token for the created user', async () => {
    const signUp = await fetch(`${baseUrl}/api/auth/sign-up/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        email: EMAIL,
        password: PASSWORD,
        name: 'Collector',
      }),
    });

    expect(signUp.status, await signUp.text()).toBe(200);

    const signIn = await fetch(`${baseUrl}/api/auth/sign-in/email`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: EMAIL, password: PASSWORD }),
    });

    expect(signIn.status, await signIn.clone().text()).toBe(200);

    const signedIn = (await signIn.json()) as {
      token?: string;
      user?: { email?: string };
    };

    expect(signedIn.user?.email).toBe(EMAIL);
    expect(signedIn.token).toBeTruthy();
    expect(signIn.headers.getSetCookie().join(';')).toMatch(
      /better-auth\.session_token/, // glossary:allow Better Auth's auth-session cookie
    );
  });
});
