import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
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
  });

  it('relaxes the Visit resolution columns and adds the Detection provisional name on a populated database (ADR-0021)', async () => {
    const initial = runDrizzleKitMigrate(databaseUrl);
    expect(initial.status, initial.stderr + initial.stdout).toBe(0);

    const projectId = randomUUID();
    const siteId = randomUUID();
    const surveyPeriodId = randomUUID();
    const protocolVersionId = randomUUID();
    const visitId = randomUUID();
    const detectionId = randomUUID();

    await query(
      databaseUrl,
      `insert into "project" (id, name, settings, taxonomic_reference_id, taxonomic_reference_version)
       values ('${projectId}',
               'Populated migration project',
               '{"validationEnabled": false, "sensitiveTaxaObfuscation": false}'::jsonb,
               'italy-vascular-flora',
               '2024.1')`,
    );
    await query(
      databaseUrl,
      `insert into "site" (id, project_id, name) values ('${siteId}', '${projectId}', 'Plot A')`,
    );
    await query(
      databaseUrl,
      `insert into "survey_period" (id, project_id, name, start_date, end_date)
       values ('${surveyPeriodId}', '${projectId}', 'Spring 2026', '2026-03-01', '2026-05-31')`,
    );
    await query(
      databaseUrl,
      `insert into "protocol_version" (id, project_id, protocol_id, version, document)
       values ('${protocolVersionId}', '${projectId}', 'standard', 1, '{}'::jsonb)`,
    );
    await query(
      databaseUrl,
      `insert into "visit"
         ("id", "project_id", "site_id", "survey_period_id", "protocol_version_id", "taxonomic_reference_id", "taxonomic_reference_version", "state", "effort", "started_at", "submitted_at")
       values
         ('${visitId}', '${projectId}', '${siteId}', '${surveyPeriodId}', '${protocolVersionId}', 'italy-vascular-flora', '2024.1', 'submitted', '{}'::jsonb, now(), now())`,
    );
    await query(
      databaseUrl,
      `insert into "detection" (id, visit_id, taxon, detected, method)
       values ('${detectionId}', '${visitId}', 'Anthus trivialis', true, 'visual')`,
    );

    // Reproduce a database on the pre-0016 schema that already holds the rows:
    // restore the NOT NULL resolution columns, drop the provisional name and
    // the exactly-one constraint, restore the taxon-keyed index, and un-record
    // the migration so `migrate` re-applies it.
    await query(
      databaseUrl,
      `alter table "detection" drop constraint if exists "detection_taxon_exactly_one"`,
    );
    await query(
      databaseUrl,
      `drop index if exists "detection_visit_taxon_target_key"`,
    );
    await query(
      databaseUrl,
      `alter table "detection" drop column if exists "provisional_name"`,
    );
    await query(
      databaseUrl,
      `alter table "detection" alter column "taxon" set not null`,
    );
    await query(
      databaseUrl,
      `create unique index "detection_visit_taxon_target_key" on "detection" using btree ("visit_id", "taxon") where not "detection"."opportunistic"`,
    );
    for (const column of [
      'survey_period_id',
      'protocol_version_id',
      'taxonomic_reference_id',
      'taxonomic_reference_version',
    ]) {
      await query(
        databaseUrl,
        `alter table "visit" alter column "${column}" set not null`,
      );
    }
    await query(
      databaseUrl,
      `delete from drizzle.__drizzle_migrations where created_at >= ${migrationTimestamp('0016_far_krista_starr')}`,
    );

    const migration = runDrizzleKitMigrate(databaseUrl);
    expect(migration.status, migration.stderr + migration.stdout).toBe(0);

    // Every existing row survives the migration.
    const visits = await query(
      databaseUrl,
      `select "id", "survey_period_id", "protocol_version_id", "taxonomic_reference_id", "taxonomic_reference_version" from "visit" where "id" = '${visitId}'`,
    );
    expect(visits).toHaveLength(1);
    expect(visits[0]!.survey_period_id).toBe(surveyPeriodId);
    expect(visits[0]!.protocol_version_id).toBe(protocolVersionId);
    expect(visits[0]!.taxonomic_reference_id).toBe('italy-vascular-flora');
    expect(visits[0]!.taxonomic_reference_version).toBe('2024.1');

    const detections = await query(
      databaseUrl,
      `select "id", "taxon", "provisional_name" from "detection" where "id" = '${detectionId}'`,
    );
    expect(detections).toHaveLength(1);
    expect(detections[0]!.taxon).toBe('Anthus trivialis');
    expect(detections[0]!.provisional_name).toBeNull();

    // The Visit resolution columns are now nullable and the Detection carries
    // the new provisional name alongside a nullable taxon.
    const visitColumns = await query(
      databaseUrl,
      `select column_name, is_nullable from information_schema.columns
       where table_schema = 'public' and table_name = 'visit'
         and column_name in ('survey_period_id', 'protocol_version_id', 'taxonomic_reference_id', 'taxonomic_reference_version')
       order by column_name`,
    );
    expect(visitColumns).toEqual([
      { column_name: 'protocol_version_id', is_nullable: 'YES' },
      { column_name: 'survey_period_id', is_nullable: 'YES' },
      { column_name: 'taxonomic_reference_id', is_nullable: 'YES' },
      { column_name: 'taxonomic_reference_version', is_nullable: 'YES' },
    ]);

    const detectionColumns = await query(
      databaseUrl,
      `select column_name, is_nullable from information_schema.columns
       where table_schema = 'public' and table_name = 'detection'
         and column_name in ('taxon', 'provisional_name')
       order by column_name`,
    );
    expect(detectionColumns).toEqual([
      { column_name: 'provisional_name', is_nullable: 'YES' },
      { column_name: 'taxon', is_nullable: 'YES' },
    ]);
  });
});
