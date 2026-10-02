import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { Module, type INestApplication } from '@nestjs/common';
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
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import { project } from '../src/db/schema.js';
import { ExportsModule } from '../src/exports/exports.module.js';
import { ExportsStore } from '../src/exports/exports.store.js';

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

interface JournalEntry {
  tag: string;
  when: number;
}

const journal = JSON.parse(
  readFileSync(
    fileURLToPath(new URL('../drizzle/meta/_journal.json', import.meta.url)),
    'utf8',
  ),
) as { entries: JournalEntry[] };

// The `created_at` drizzle-kit writes for a migration is its journal `when`;
// matching on it lets a test un-record exactly the export migration so `migrate`
// re-applies it on top of a database that already holds data, rather than the
// newest migration, which a later Sub-task appends.
function migrationTimestamp(tag: string): number {
  const entry = journal.entries.find((candidate) => candidate.tag === tag);
  if (entry === undefined) {
    throw new Error(`migration ${tag} is not in the drizzle journal`);
  }
  return entry.when;
}

@Module({
  imports: [ExportsModule, DatabaseModule],
})
class TestModule {}

describe('Export store', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;
  let app: INestApplication;
  let db: NodePgDatabase;
  let exports: ExportsStore;

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    databaseUrl = container.getConnectionUri();
    process.env.DATABASE_URL = databaseUrl;
    process.env.REDIS_URL = 'redis://127.0.0.1:6379';

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
    await app.init();
    db = app.get<NodePgDatabase>(DATABASE);
    exports = app.get(ExportsStore);
  }, 180_000);

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await container?.stop();
  });

  async function seedProject(): Promise<string> {
    const [created] = await db
      .insert(project)
      .values({
        name: 'Export store project',
        settings: { validationEnabled: false, sensitiveTaxaObfuscation: false },
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
      })
      .returning();
    return created!.id;
  }

  it('creates the export table with its columns through the forward-only migration', async () => {
    const result = await db.execute(
      sql`select column_name from information_schema.columns where table_schema = 'public' and table_name = 'export'`,
    );
    const names = (result.rows as Array<{ column_name: string }>).map(
      (row) => row.column_name,
    );
    for (const column of [
      'project_id',
      'format',
      'state',
      'storage_key',
      'error',
    ]) {
      expect(names).toContain(column);
    }
  });

  it('saves an export record and reloads every column unchanged by id', async () => {
    const projectId = await seedProject();

    const saved = await exports.create({
      projectId,
      format: 'darwin_core',
      state: 'succeeded',
      storageKey: 'exports/abc123',
      error: null,
    });

    const loaded = await exports.findById(saved.id);

    expect(loaded).toEqual(saved);
  });

  it('records the failure reason on a failed export and leaves the artifact key empty', async () => {
    const projectId = await seedProject();

    const saved = await exports.create({
      projectId,
      format: 'geopackage',
      state: 'failed',
      error: 'generator timed out',
    });

    const loaded = await exports.findById(saved.id);

    expect(loaded).toEqual(saved);
    expect(loaded!.state).toBe('failed');
    expect(loaded!.error).toBe('generator timed out');
    expect(loaded!.storageKey).toBeNull();
  });

  it('defaults a newly requested export to the requested state', async () => {
    const projectId = await seedProject();

    const saved = await exports.create({ projectId, format: 'csv' });

    expect(saved.state).toBe('requested');
    expect(saved.storageKey).toBeNull();
    expect(saved.error).toBeNull();
  });

  it('applies the export migration to a populated database from the migration that precedes it', async () => {
    const projectId = await seedProject();

    await db.execute(sql`drop table if exists "export"`);
    await db.execute(sql`drop type if exists "export_state"`);
    await db.execute(
      sql`delete from drizzle.__drizzle_migrations where created_at >= ${migrationTimestamp('0014_wakeful_doctor_spectrum')}`,
    );

    const migration = runDrizzleKitMigrate(databaseUrl);
    expect(migration.status, migration.stderr + migration.stdout).toBe(0);

    const ownerRows = (
      await db.execute(sql`select id from "project" where id = ${projectId}`)
    ).rows as Array<{ id: string }>;
    expect(ownerRows).toHaveLength(1);

    const tableRows = (
      await db.execute(
        sql`select table_name from information_schema.tables where table_schema = 'public' and table_name = 'export'`,
      )
    ).rows as Array<{ table_name: string }>;
    expect(tableRows).toHaveLength(1);
  });
});
