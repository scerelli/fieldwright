import type { INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { sql } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { DatabaseModule } from '../src/db/database.module.js';
import {
  DATABASE,
  DATABASE_POOL,
  QUERY_EXECUTOR,
  createDatabasePool,
  type QueryExecutor,
} from '../src/db/database.provider.js';

describe('createDatabasePool', () => {
  it('builds a pg Pool from a connection string', async () => {
    const url = 'postgres://ibis:secret@localhost:5432/ibis';

    const pool = createDatabasePool(url);

    expect(pool).toBeInstanceOf(Pool);
    expect(pool.options.connectionString).toBe(url);

    await pool.end();
  });

  it('fails loud when the connection string is missing', () => {
    expect(() => createDatabasePool(undefined)).toThrow(/DATABASE_URL/);
  });
});

describe('DatabaseModule', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:18').start();
    databaseUrl = container.getConnectionUri();
  }, 120_000);

  afterAll(async () => {
    await container.stop();
  });

  async function createDatabaseApp(): Promise<INestApplication> {
    process.env.DATABASE_URL = databaseUrl;

    return NestFactory.create(DatabaseModule, { logger: false });
  }

  it('exposes a pg pool built from DATABASE_URL', async () => {
    const app = await createDatabaseApp();

    const pool = app.get<Pool>(DATABASE_POOL);

    expect(pool).toBeInstanceOf(Pool);
    expect(pool.options.connectionString).toBe(databaseUrl);

    await pool.end();
    await app.close();
  });

  it('exposes a query executor that runs SELECT 1 against a reachable database', async () => {
    const app = await createDatabaseApp();

    const executor = app.get<QueryExecutor>(QUERY_EXECUTOR);
    const result = await executor.query('SELECT 1 AS one');

    expect(result.rows).toEqual([{ one: 1 }]);

    await app.get<Pool>(DATABASE_POOL).end();
    await app.close();
  });

  it('exposes a Drizzle query executor that runs SELECT 1', async () => {
    const app = await createDatabaseApp();

    const db = app.get<NodePgDatabase>(DATABASE);
    const result = await db.execute(sql`SELECT 1 AS one`);

    expect(result.rows).toEqual([{ one: 1 }]);

    await app.get<Pool>(DATABASE_POOL).end();
    await app.close();
  });
});
