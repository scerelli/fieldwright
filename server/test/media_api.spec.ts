import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, readdir, rm } from 'node:fs/promises';
import type { AddressInfo } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
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
import { MediaModule } from '../src/media/media.module.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

const EMAIL = 'collector@example.com';
const PASSWORD = 'correct-horse-battery-staple';

/**
 * The one distinct Evidence byte string this suite ever uploads, so the
 * content-addressed media root holds exactly one stored file throughout.
 */
const EVIDENCE = new TextEncoder().encode('ibis-evidence-photo-bytes');
const EVIDENCE_SHA256 =
  'a09a3a2aa03e171462980147500b8e5eb32900f0edf31bb73f6cfac150ed853f';
const UNKNOWN_KEY = '0'.repeat(64);

/** The upload cap the module under test is configured with in this suite. */
const MAX_UPLOAD_BYTES = 64;

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

@Module({
  imports: [MediaModule, AuthModule, DatabaseModule],
})
class TestModule {}

describe('media REST surface', () => {
  let container: StartedPostgreSqlContainer;
  let app: INestApplication;
  let baseUrl: string;
  let cookie: string;
  let mediaRoot: string;

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    const databaseUrl = container.getConnectionUri();
    process.env.DATABASE_URL = databaseUrl;
    process.env.BETTER_AUTH_SECRET =
      'test-only-secret-at-least-thirty-two-characters';

    mediaRoot = await mkdtemp(join(tmpdir(), 'ibis-media-api-'));
    process.env.MEDIA_ROOT = mediaRoot;
    process.env.MEDIA_MAX_UPLOAD_BYTES = String(MAX_UPLOAD_BYTES);

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
    if (mediaRoot !== undefined) {
      await rm(mediaRoot, { recursive: true, force: true });
    }
  });

  function upload(
    bytes: Uint8Array<ArrayBuffer>,
    headers: Record<string, string> = {},
  ): Promise<Response> {
    return fetch(`${baseUrl}/api/v1/media`, {
      method: 'POST',
      headers: { 'content-type': 'application/octet-stream', ...headers },
      body: new Blob([bytes]),
    });
  }

  function download(
    storageKey: string,
    headers: Record<string, string> = {},
  ): Promise<Response> {
    return fetch(`${baseUrl}/api/v1/media/${storageKey}`, { headers });
  }

  it('stores uploaded Evidence and returns its storageKey and sha256 (C1)', async () => {
    const response = await upload(EVIDENCE, { cookie });

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as {
      storageKey: string;
      sha256: string;
    };
    expect(body.storageKey).toBe(EVIDENCE_SHA256);
    expect(body.sha256).toBe(EVIDENCE_SHA256);
  });

  it('returns the exact bytes previously uploaded (C2)', async () => {
    const response = await download(EVIDENCE_SHA256, { cookie });

    expect(response.status, await response.clone().text()).toBe(200);
    expect(response.headers.get('content-type')).toBe(
      'application/octet-stream',
    );
    expect(Buffer.from(await response.arrayBuffer())).toEqual(
      Buffer.from(EVIDENCE),
    );
  });

  it('returns 404 for an unknown storageKey (C3)', async () => {
    const response = await download(UNKNOWN_KEY, { cookie });

    expect(response.status).toBe(404);
    const body = (await response.json()) as { message: string };
    expect(body.message).toBe('Not Found');
  });

  it('rejects an unauthenticated upload with 401 (C4)', async () => {
    const response = await upload(EVIDENCE);

    expect(response.status).toBe(401);
  });

  it('stores identical bytes once and returns the same storageKey (C5)', async () => {
    const first = await upload(EVIDENCE, { cookie });
    const second = await upload(EVIDENCE, { cookie });

    expect(first.status, await first.clone().text()).toBe(201);
    expect(second.status, await second.clone().text()).toBe(201);
    const firstBody = (await first.json()) as { storageKey: string };
    const secondBody = (await second.json()) as { storageKey: string };
    expect(secondBody.storageKey).toBe(firstBody.storageKey);

    const stored = await readdir(mediaRoot);
    expect(stored).toHaveLength(1);
    expect(stored[0]).toBe(EVIDENCE_SHA256);
  });

  it('rejects an upload over the configured limit with 413 and stores nothing', async () => {
    const oversized = new Uint8Array(MAX_UPLOAD_BYTES + 1).fill(0x42);
    const before = await readdir(mediaRoot);

    const response = await upload(oversized, { cookie });

    expect(response.status, await response.clone().text()).toBe(413);
    const after = await readdir(mediaRoot);
    expect(after).toEqual(before);
    expect(after).not.toContain(
      createHash('sha256').update(oversized).digest('hex'),
    );
  });

  it('accepts an upload exactly at the configured limit', async () => {
    const atLimit = new Uint8Array(MAX_UPLOAD_BYTES).fill(0x41);

    const response = await upload(atLimit, { cookie });

    expect(response.status, await response.clone().text()).toBe(201);
    const body = (await response.json()) as { storageKey: string };
    expect(body.storageKey).toBe(
      createHash('sha256').update(atLimit).digest('hex'),
    );
  });

  it('rejects an over-limit upload with 413 when Content-Length is absent', async () => {
    const oversized = new Uint8Array(MAX_UPLOAD_BYTES * 2).fill(0x43);
    const body = new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(oversized);
        controller.close();
      },
    });

    const response = await fetch(`${baseUrl}/api/v1/media`, {
      method: 'POST',
      headers: { 'content-type': 'application/octet-stream', cookie },
      body,
      duplex: 'half',
    } as RequestInit);

    expect(response.status).toBe(413);
  });
});
