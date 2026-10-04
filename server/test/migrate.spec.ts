import { spawnSync } from 'node:child_process';
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);
const migrationCount = readdirSync(
  fileURLToPath(new URL('../drizzle', import.meta.url)),
).filter((entry) => entry.endsWith('.sql')).length;

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
// matching on it lets a test un-record exactly the Project description
// migration so `migrate` re-applies it on a populated database, rather than the
// newest migration, which a later Sub-task appends.
function migrationTimestamp(tag: string): number {
  const entry = journal.entries.find((candidate) => candidate.tag === tag);
  if (entry === undefined) {
    throw new Error(`migration ${tag} is not in the drizzle journal`);
  }
  return entry.when;
}

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

async function query(databaseUrl: string, text: string) {
  const pool = new Pool({ connectionString: databaseUrl });
  try {
    const result = await pool.query(text);
    return result.rows;
  } finally {
    await pool.end();
  }
}

describe('baseline migration', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    databaseUrl = container.getConnectionUri();
  }, 180_000);

  afterAll(async () => {
    await container.stop();
  });

  it('creates the postgis extension on a fresh database', async () => {
    const migrate = runDrizzleKitMigrate(databaseUrl);

    expect(migrate.status, migrate.stderr).toBe(0);

    const extensions = await query(
      databaseUrl,
      "SELECT extname FROM pg_extension WHERE extname = 'postgis'",
    );

    expect(extensions).toEqual([{ extname: 'postgis' }]);
  });

  it('applies forward-only: re-running migrate adds no migration', async () => {
    const applied = () =>
      query(
        databaseUrl,
        'SELECT count(*)::int AS count FROM drizzle.__drizzle_migrations',
      );

    const first = runDrizzleKitMigrate(databaseUrl);
    expect(first.status, first.stderr).toBe(0);
    const before = await applied();
    expect(before).toEqual([{ count: migrationCount }]);

    const rerun = runDrizzleKitMigrate(databaseUrl);
    expect(rerun.status, rerun.stderr).toBe(0);

    expect(await applied()).toEqual(before);
  });

  it('adds the nullable Project description on a populated database', async () => {
    const initial = runDrizzleKitMigrate(databaseUrl);
    expect(initial.status, initial.stderr + initial.stdout).toBe(0);

    await query(
      databaseUrl,
      `insert into "project" (name, settings, taxonomic_reference_id, taxonomic_reference_version)
       values ('Populated project',
               '{"validationEnabled": false, "sensitiveTaxaObfuscation": false}'::jsonb,
               'italy-vascular-flora',
               '2024.1')`,
    );

    await query(
      databaseUrl,
      'alter table "project" drop column if exists "description"',
    );
    await query(
      databaseUrl,
      `delete from drizzle.__drizzle_migrations where created_at >= ${migrationTimestamp('0015_condemned_the_twelve')}`,
    );

    const migration = runDrizzleKitMigrate(databaseUrl);
    expect(migration.status, migration.stderr + migration.stdout).toBe(0);

    const columns = await query(
      databaseUrl,
      `select column_name, is_nullable from information_schema.columns
       where table_schema = 'public' and table_name = 'project' and column_name = 'description'`,
    );
    expect(columns).toEqual([
      { column_name: 'description', is_nullable: 'YES' },
    ]);

    const rows = await query(
      databaseUrl,
      `select id, description from "project" where name = 'Populated project'`,
    );
    expect(rows).toHaveLength(1);
    expect(rows[0]!.description).toBeNull();
  }, 30_000);

  it('makes the pinned Taxonomic reference nullable on a populated database', async () => {
    const initial = runDrizzleKitMigrate(databaseUrl);
    expect(initial.status, initial.stderr + initial.stdout).toBe(0);

    await query(
      databaseUrl,
      `insert into "project" (name, settings, taxonomic_reference_id, taxonomic_reference_version)
       values ('Pinned project',
               '{"validationEnabled": false, "sensitiveTaxaObfuscation": true}'::jsonb,
               'italy-vascular-flora',
               '2024.1')`,
    );

    await query(
      databaseUrl,
      'alter table "project" alter column "taxonomic_reference_id" set not null',
    );
    await query(
      databaseUrl,
      'alter table "project" alter column "taxonomic_reference_version" set not null',
    );
    await query(
      databaseUrl,
      `delete from drizzle.__drizzle_migrations where created_at >= ${migrationTimestamp('0016_bored_loki')}`,
    );

    const migration = runDrizzleKitMigrate(databaseUrl);
    expect(migration.status, migration.stderr + migration.stdout).toBe(0);

    const columns = await query(
      databaseUrl,
      `select column_name, is_nullable from information_schema.columns
       where table_schema = 'public' and table_name = 'project'
         and column_name in ('taxonomic_reference_id', 'taxonomic_reference_version')
       order by column_name`,
    );
    expect(columns).toEqual([
      { column_name: 'taxonomic_reference_id', is_nullable: 'YES' },
      { column_name: 'taxonomic_reference_version', is_nullable: 'YES' },
    ]);

    const rows = await query(
      databaseUrl,
      `select id, taxonomic_reference_id, taxonomic_reference_version from "project" where name = 'Pinned project'`,
    );
    expect(rows).toHaveLength(1);
    expect(rows[0]!.taxonomic_reference_id).toBe('italy-vascular-flora');
    expect(rows[0]!.taxonomic_reference_version).toBe('2024.1');
  }, 30_000);
});
