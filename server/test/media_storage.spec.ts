import { createHash } from 'node:crypto';
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { loadMediaConfig } from '../src/media/media.config.js';
import type { MediaStorage } from '../src/media/media.storage.js';
import { createVolumeStorage } from '../src/media/volume.storage.js';

const HELLO = new TextEncoder().encode('hello');
const HELLO_SHA256 =
  '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

describe('createVolumeStorage', () => {
  let root: string;
  let storage: MediaStorage;

  beforeEach(async () => {
    root = await mkdtemp(join(tmpdir(), 'ibis-media-'));
    storage = createVolumeStorage(root);
  });

  afterEach(async () => {
    await rm(root, { recursive: true, force: true });
  });

  it('returns the lowercase-hex SHA-256 of the bytes as storageKey and sha256', async () => {
    const stored = await storage.store(HELLO);

    expect(stored.storageKey).toBe(HELLO_SHA256);
    expect(stored.sha256).toBe(HELLO_SHA256);
    expect(stored.storageKey).toMatch(/^[0-9a-f]{64}$/);
    expect(createHash('sha256').update(HELLO).digest('hex')).toBe(
      stored.storageKey,
    );
  });

  it('stores the bytes at the content-hashed key under the media root', async () => {
    const stored = await storage.store(HELLO);

    const onDisk = await readFile(join(root, stored.storageKey));

    expect(Buffer.from(onDisk)).toEqual(Buffer.from(HELLO));
  });

  it('returns the same key for identical bytes and does not rewrite the stored file', async () => {
    const first = await storage.store(HELLO);
    const target = join(root, first.storageKey);
    const before = await stat(target);

    await new Promise((resolve) => setTimeout(resolve, 20));

    const second = await storage.store(HELLO);
    const after = await stat(target);

    expect(second).toEqual(first);
    expect(after.mtimeMs).toBe(before.mtimeMs);
    expect(Buffer.from(await readFile(target))).toEqual(Buffer.from(HELLO));
  });

  it('fetches the exact bytes that were stored', async () => {
    const { storageKey } = await storage.store(HELLO);

    const bytes = await storage.fetch(storageKey);

    expect(bytes).not.toBeNull();
    if (bytes === null) {
      throw new Error('expected stored bytes');
    }
    expect(Buffer.from(bytes)).toEqual(Buffer.from(HELLO));
  });

  it('reports not-found as null for a key that names no stored file', async () => {
    const missing = await storage.fetch('0'.repeat(64));

    expect(missing).toBeNull();
  });
});

describe('createVolumeStorage fetch key validation', () => {
  let base: string;
  let root: string;
  let storage: MediaStorage;

  beforeEach(async () => {
    base = await mkdtemp(join(tmpdir(), 'ibis-media-root-'));
    root = join(base, 'media');
    storage = createVolumeStorage(root);
    await mkdir(root, { recursive: true });
    await writeFile(join(base, 'secret.txt'), 'secret');
  });

  afterEach(async () => {
    await rm(base, { recursive: true, force: true });
  });

  it('reports not-found for a traversal key and never reads outside the root', async () => {
    const bytes = await storage.fetch('../secret.txt');

    expect(bytes).toBeNull();
    expect(Buffer.from(await readFile(join(base, 'secret.txt')))).toEqual(
      Buffer.from('secret'),
    );
  });

  it.each<string>([
    '/etc/passwd',
    '../../etc/passwd',
    'ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789',
    'abc',
    '',
  ])('reports not-found for malformed key %j', async (key) => {
    expect(await storage.fetch(key)).toBeNull();
  });
});

describe('loadMediaConfig', () => {
  it('defaults the media root to /data/media and the backend to volume', () => {
    const config = loadMediaConfig({});

    expect(config.root).toBe('/data/media');
    expect(config.backend).toBe('volume');
  });

  it('reads the media root and backend from the environment', () => {
    const config = loadMediaConfig({
      MEDIA_ROOT: '/srv/ibis/media',
      MEDIA_STORAGE_BACKEND: 'volume',
    });

    expect(config.root).toBe('/srv/ibis/media');
    expect(config.backend).toBe('volume');
  });

  it('fails loud on an unsupported backend', () => {
    expect(() => loadMediaConfig({ MEDIA_STORAGE_BACKEND: 's3' })).toThrow(/s3/);
  });

  it('treats an empty backend setting as unset, like an empty media root', () => {
    const config = loadMediaConfig({ MEDIA_STORAGE_BACKEND: '' });

    expect(config.backend).toBe('volume');
  });
});
