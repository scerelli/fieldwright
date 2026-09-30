import { spawnSync } from 'node:child_process';
import type { AddressInfo } from 'node:net';
import { fileURLToPath } from 'node:url';
import type { INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import {
  RedisContainer,
  type StartedRedisContainer,
} from '@testcontainers/redis';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AppModule } from '../src/app.module.js';
import { DATABASE_POOL } from '../src/db/database.provider.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

describe('served AppModule', () => {
  let postgres: StartedPostgreSqlContainer;
  let redisContainer: StartedRedisContainer;
  let app: INestApplication;
  let baseUrl: string;

  beforeAll(async () => {
    postgres = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    redisContainer = await new RedisContainer('redis:7').start();

    process.env.DATABASE_URL = postgres.getConnectionUri();
    process.env.REDIS_URL = redisContainer.getConnectionUrl();
    process.env.BETTER_AUTH_SECRET =
      'test-only-secret-at-least-thirty-two-characters';

    const migrate = runDrizzleKitMigrate(process.env.DATABASE_URL);
    if (migrate.status !== 0) {
      throw new Error(
        `drizzle-kit migrate failed: ${migrate.stderr}${migrate.stdout}`,
      );
    }

    app = await NestFactory.create(AppModule, { logger: false });
    await app.listen(0, '127.0.0.1');
    const address = app.getHttpServer().address() as AddressInfo;
    baseUrl = `http://127.0.0.1:${address.port}`;
  }, 240_000);

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await redisContainer?.stop();
    await postgres?.stop();
  });

  it('serves an auth route instead of 404', async () => {
    const response = await fetch(
      `${baseUrl}/api/auth/get-session`, // glossary:allow Better Auth's auth-session route, not the Visit
    );

    expect(response.status).not.toBe(404);
  });

  it('serves a projects route instead of 404', async () => {
    const response = await fetch(`${baseUrl}/projects`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({}),
    });

    expect(response.status).not.toBe(404);
  });

  it('GET /readyz returns 200 with the database and Redis reachable', async () => {
    const body = await readyzWhenSettled(baseUrl);

    expect(body.dependencies.database).toBe(true);
    expect(body.dependencies.redis).toBe(true);
  });
});

async function readyzWhenSettled(baseUrl: string): Promise<{
  dependencies: Record<string, boolean>;
}> {
  let lastStatus = 0;
  let lastBody: { dependencies: Record<string, boolean> } = {
    dependencies: {},
  };

  for (let attempt = 0; attempt < 20; attempt += 1) {
    const response = await fetch(`${baseUrl}/readyz`);
    lastStatus = response.status;
    lastBody = (await response.json()) as {
      dependencies: Record<string, boolean>;
    };
    if (response.status === 200) {
      return lastBody;
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }

  throw new Error(
    `/readyz never returned 200 (last status ${lastStatus}): ${JSON.stringify(lastBody)}`,
  );
}
