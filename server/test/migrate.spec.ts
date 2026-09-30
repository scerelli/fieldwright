import { spawnSync } from 'node:child_process';
import { readdirSync } from 'node:fs';
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
});
