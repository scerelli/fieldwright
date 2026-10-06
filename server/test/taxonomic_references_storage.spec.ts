import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import {
  parseReferenceArtifact,
  type ReferenceArtifact,
} from '../src/taxonomic-references/reference-artifact.js';
import { loadTaxonomicReferencesConfig } from '../src/taxonomic-references/taxonomic-references.config.js';
import {
  createReferenceVolumeStorage,
  MalformedReferenceArtifactError,
  type ReferenceStorage,
} from '../src/taxonomic-references/taxonomic-references.storage.js';

const ARTIFACT: ReferenceArtifact = {
  id: 'italy-vascular-flora',
  version: '2024.1',
  label: 'Italy vascular flora',
  taxonGroup: 'vascular-plants',
  taxa: [{ abbreviation: 'AchMil', name: 'Achillea millefolium' }],
};

describe('createReferenceVolumeStorage', () => {
  let base: string;
  let root: string;
  let storage: ReferenceStorage;

  beforeEach(async () => {
    base = await mkdtemp(join(tmpdir(), 'ibis-reference-store-'));
    root = join(base, 'references');
    storage = createReferenceVolumeStorage(root);
    await mkdir(root, { recursive: true });
  });

  afterEach(async () => {
    await rm(base, { recursive: true, force: true });
  });

  async function writeArtifactAt(
    id: string,
    version: string,
    contents: unknown,
  ): Promise<void> {
    await mkdir(join(root, id), { recursive: true });
    await writeFile(
      join(root, id, `${version}.json`),
      typeof contents === 'string' ? contents : JSON.stringify(contents),
      'utf8',
    );
  }

  it('reads the artifact stored for id+version', async () => {
    await writeArtifactAt(ARTIFACT.id, ARTIFACT.version, ARTIFACT);

    expect(await storage.readArtifact(ARTIFACT.id, ARTIFACT.version)).toEqual(
      ARTIFACT,
    );
  });

  it('reports not-found for an artifact the volume does not hold', async () => {
    expect(await storage.readArtifact(ARTIFACT.id, '1999.1')).toBeNull();
  });

  it('rejects malformed JSON with a named error rather than serving it', async () => {
    await writeArtifactAt(ARTIFACT.id, ARTIFACT.version, '{ not json');

    await expect(
      storage.readArtifact(ARTIFACT.id, ARTIFACT.version),
    ).rejects.toBeInstanceOf(MalformedReferenceArtifactError);
  });

  it('reports not-found when the id names a file rather than a directory (ENOTDIR)', async () => {
    await writeFile(join(root, 'stray'), 'not a directory');

    expect(await storage.readArtifact('stray', ARTIFACT.version)).toBeNull();
  });

  it('reports not-found when the artifact path is a directory (EISDIR)', async () => {
    await mkdir(join(root, ARTIFACT.id, `${ARTIFACT.version}.json`), {
      recursive: true,
    });

    expect(
      await storage.readArtifact(ARTIFACT.id, ARTIFACT.version),
    ).toBeNull();
  });

  it('reports not-found for a traversal id and never reads outside the root', async () => {
    await writeFile(join(base, 'secret.json'), JSON.stringify(ARTIFACT));

    const artifact = await storage.readArtifact('..', 'secret');

    expect(artifact).toBeNull();
    expect(
      JSON.parse(await readFile(join(base, 'secret.json'), 'utf8')),
    ).toEqual(ARTIFACT);
  });

  it('reports not-found for a traversal version and never reads outside the root', async () => {
    await writeFile(join(root, 'secret.json'), JSON.stringify(ARTIFACT));

    const artifact = await storage.readArtifact(ARTIFACT.id, '../secret');

    expect(artifact).toBeNull();
    expect(
      JSON.parse(await readFile(join(root, 'secret.json'), 'utf8')),
    ).toEqual(ARTIFACT);
  });

  it.each<[string, string]>([
    ['..', '2024.1'],
    ['../secret', '2024.1'],
    ['a/../../secret', '2024.1'],
    ['/etc/passwd', '2024.1'],
    ['', '2024.1'],
    ['.', '2024.1'],
    ['italy-vascular-flora', '..'],
    ['italy-vascular-flora', 'a/b'],
    ['italy-vascular-flora', ''],
    ['italy-vascular-flora', '.'],
  ])(
    'reports not-found for a traversal or malformed segment %s / %s',
    async (id, version) => {
      expect(await storage.readArtifact(id, version)).toBeNull();
    },
  );
});

describe('parseReferenceArtifact', () => {
  it('projects a valid artifact and drops unknown fields', () => {
    const raw = {
      ...ARTIFACT,
      unexpected: 'ignored',
      taxa: [{ ...ARTIFACT.taxa[0], extra: 'ignored' }],
    };

    expect(parseReferenceArtifact(raw)).toEqual(ARTIFACT);
  });

  it.each<[string, unknown]>([
    ['null', null],
    ['an array', [ARTIFACT]],
    ['a string', 'artifact'],
    ['a number', 1],
  ])('returns null when the raw value is %s', (_name, raw) => {
    expect(parseReferenceArtifact(raw)).toBeNull();
  });

  it.each(['id', 'version', 'label', 'taxonGroup'])(
    'returns null when the required field %s is missing',
    (field) => {
      const raw = { ...ARTIFACT } as Record<string, unknown>;
      delete raw[field];

      expect(parseReferenceArtifact(raw)).toBeNull();
    },
  );

  it.each(['id', 'version', 'label', 'taxonGroup'])(
    'returns null when the required field %s is empty',
    (field) => {
      expect(parseReferenceArtifact({ ...ARTIFACT, [field]: '' })).toBeNull();
    },
  );

  it.each(['id', 'version', 'label', 'taxonGroup'])(
    'returns null when the required field %s is not a string',
    (field) => {
      expect(parseReferenceArtifact({ ...ARTIFACT, [field]: 1 })).toBeNull();
    },
  );

  it('returns null when taxa is not an array', () => {
    expect(parseReferenceArtifact({ ...ARTIFACT, taxa: 'Aves' })).toBeNull();
  });

  it('returns null when a taxa entry is not a record', () => {
    expect(parseReferenceArtifact({ ...ARTIFACT, taxa: ['Aves'] })).toBeNull();
  });

  it.each(['abbreviation', 'name'])(
    'returns null when a taxon %s is missing',
    (field) => {
      const taxon = { ...ARTIFACT.taxa[0] } as Record<string, unknown>;
      delete taxon[field];

      expect(parseReferenceArtifact({ ...ARTIFACT, taxa: [taxon] })).toBeNull();
    },
  );

  it.each(['abbreviation', 'name'])(
    'returns null when a taxon %s is empty',
    (field) => {
      const taxa = [{ ...ARTIFACT.taxa[0], [field]: '' }];

      expect(parseReferenceArtifact({ ...ARTIFACT, taxa })).toBeNull();
    },
  );
});

describe('loadTaxonomicReferencesConfig', () => {
  it('defaults the reference root to /data/references', () => {
    expect(loadTaxonomicReferencesConfig({}).root).toBe('/data/references');
  });

  it('reads the reference root from the environment', () => {
    expect(
      loadTaxonomicReferencesConfig({ REFERENCE_ROOT: '/srv/ibis/references' })
        .root,
    ).toBe('/srv/ibis/references');
  });

  it('treats an empty reference root as unset', () => {
    expect(loadTaxonomicReferencesConfig({ REFERENCE_ROOT: '' }).root).toBe(
      '/data/references',
    );
  });
});
