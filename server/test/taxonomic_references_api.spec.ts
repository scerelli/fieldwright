import { spawnSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import type { AddressInfo } from 'node:net';
import { dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { Module, type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AuthModule } from '../src/auth/auth.module.js';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE_POOL } from '../src/db/database.provider.js';
import { TaxonomicReferencesModule } from '../src/taxonomic-references/taxonomic-references.module.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);
const goldenPath = fileURLToPath(
  new URL('./fixtures/taxonomic-reference.golden.json', import.meta.url),
);

const EMAIL = 'collector@example.com';
const PASSWORD = 'correct-horse-battery-staple';

/**
 * The reference the golden fixture describes. It is the same id+version the
 * `projects` suites pin a Project to, so the artifact the client caches
 * resolves the taxa a Project records.
 */
const REFERENCE_ID = 'italy-vascular-flora';
const REFERENCE_VERSION = '2024.1';

interface ReferenceArtifactBody {
  id: string;
  version: string;
  label: string;
  taxonGroup: string;
  taxa: { abbreviation: string; name: string }[];
}

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

@Module({
  imports: [TaxonomicReferencesModule, AuthModule, DatabaseModule],
})
class TestModule {}

describe('GET /api/v1/taxonomic-references/:id/versions/:version', () => {
  let container: StartedPostgreSqlContainer;
  let app: INestApplication;
  let baseUrl: string;
  let cookie: string;
  let referenceRoot: string;
  let golden: ReferenceArtifactBody;

  beforeAll(async () => {
    golden = JSON.parse(
      await readFile(goldenPath, 'utf8'),
    ) as ReferenceArtifactBody;

    container = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    const databaseUrl = container.getConnectionUri();
    process.env.DATABASE_URL = databaseUrl;
    process.env.BETTER_AUTH_SECRET =
      'test-only-secret-at-least-thirty-two-characters';

    referenceRoot = await mkdtemp(join(tmpdir(), 'ibis-reference-api-'));
    process.env.REFERENCE_ROOT = referenceRoot;

    const migrate = runDrizzleKitMigrate(databaseUrl);
    if (migrate.status !== 0) {
      throw new Error(
        `drizzle-kit migrate failed: ${migrate.stderr}${migrate.stdout}`,
      );
    }

    await importGolden();

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
    if (referenceRoot !== undefined) {
      await rm(referenceRoot, { recursive: true, force: true });
    }
  });

  /**
   * Imports the golden artifact the way an operator would: the file is placed
   * on the reference volume under its id and version. Nothing is read here —
   * the server indexes and serves what the volume holds.
   */
  async function importGolden(): Promise<void> {
    await writeReference(golden);
  }

  async function writeReference(
    artifact: ReferenceArtifactBody,
  ): Promise<void> {
    const file = join(referenceRoot, artifact.id, `${artifact.version}.json`);
    await mkdir(dirname(file), { recursive: true });
    await writeFile(file, JSON.stringify(artifact), 'utf8');
  }

  function get(
    id: string,
    version: string,
    options: { cookie?: string; extra?: string } = {},
  ): Promise<Response> {
    const extra = options.extra ? `?${options.extra}` : '';
    return fetch(
      `${baseUrl}/api/v1/taxonomic-references/${id}/versions/${version}${extra}`,
      { headers: options.cookie ? { cookie: options.cookie } : {} },
    );
  }

  it('returns the artifact (its taxa) for an imported reference file (C1)', async () => {
    const response = await get(REFERENCE_ID, REFERENCE_VERSION, { cookie });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as ReferenceArtifactBody;
    expect(body.id).toBe(REFERENCE_ID);
    expect(body.version).toBe(REFERENCE_VERSION);
    expect(body.taxa).toHaveLength(3);
  });

  it('serves an artifact that matches the golden fixture (C2)', async () => {
    const response = await get(REFERENCE_ID, REFERENCE_VERSION, { cookie });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as ReferenceArtifactBody;
    expect(body).toEqual(golden);
  });

  it('serves the read endpoint under the /api/v1 prefix (C3)', async () => {
    const underPrefix = await get(REFERENCE_ID, REFERENCE_VERSION, { cookie });
    expect(underPrefix.status).toBe(200);

    const withoutPrefix = await fetch(
      `${baseUrl}/taxonomic-references/${REFERENCE_ID}/versions/${REFERENCE_VERSION}`,
      { headers: { cookie } },
    );
    expect(withoutPrefix.status).toBe(404);
  });

  it('accepts and ignores an unknown query parameter (C3)', async () => {
    const response = await get(REFERENCE_ID, REFERENCE_VERSION, {
      cookie,
      extra: 'unknown=1',
    });

    expect(response.status, await response.clone().text()).toBe(200);
    const body = (await response.json()) as ReferenceArtifactBody;
    expect(body).toEqual(golden);
  });

  it('ignores unknown fields in an imported reference file (C3)', async () => {
    const withUnknownFields = {
      ...golden,
      unexpected: 'ignored',
      nested: { shape: 'ignored' },
    };
    await writeReference(withUnknownFields);

    try {
      const response = await get(REFERENCE_ID, REFERENCE_VERSION, { cookie });

      expect(response.status, await response.clone().text()).toBe(200);
      const body = (await response.json()) as ReferenceArtifactBody;
      expect(body).toEqual(golden);
      expect(body).not.toHaveProperty('unexpected');
      expect(body).not.toHaveProperty('nested');
    } finally {
      await importGolden();
    }
  });

  it('returns 404 for a version the volume does not hold', async () => {
    const response = await get(REFERENCE_ID, '1999.1', { cookie });

    expect(response.status).toBe(404);
  });

  it('rejects a malformed reference file rather than serving it (C2)', async () => {
    const brokenId = 'broken-reference';
    const file = join(referenceRoot, brokenId, '1.json');
    await mkdir(dirname(file), { recursive: true });
    await writeFile(file, '{ not json', 'utf8');

    try {
      const response = await get(brokenId, '1', { cookie });

      expect(response.status).toBe(500);
      const body = (await response.json()) as { message?: string };
      expect(body.message).toContain(brokenId);
    } finally {
      await rm(join(referenceRoot, brokenId), { recursive: true, force: true });
    }
  });

  it('rejects an unauthenticated read (C3, additive surface is authenticated)', async () => {
    const response = await get(REFERENCE_ID, REFERENCE_VERSION);

    expect(response.status).toBe(401);
  });
});
