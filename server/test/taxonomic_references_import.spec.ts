import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { InternalServerErrorException } from '@nestjs/common';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import type { ReferenceArtifact } from '../src/taxonomic-references/reference-artifact.js';
import { TaxonomicReferencesService } from '../src/taxonomic-references/taxonomic-references.service.js';
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

describe('operator-supplied reference files', () => {
  let base: string;
  let root: string;
  let storage: ReferenceStorage;
  let service: TaxonomicReferencesService;

  beforeEach(async () => {
    base = await mkdtemp(join(tmpdir(), 'ibis-reference-import-'));
    root = join(base, 'references');
    storage = createReferenceVolumeStorage(root);
    service = new TaxonomicReferencesService(storage);
    await mkdir(root, { recursive: true });
  });

  afterEach(async () => {
    await rm(base, { recursive: true, force: true });
  });

  async function place(id: string, version: string, contents: string) {
    await mkdir(join(root, id), { recursive: true });
    await writeFile(join(root, id, `${version}.json`), contents, 'utf8');
  }

  it('indexes and serves a valid versioned reference file by id+version (C1)', async () => {
    await place(ARTIFACT.id, ARTIFACT.version, JSON.stringify(ARTIFACT));

    expect(await storage.readArtifact(ARTIFACT.id, ARTIFACT.version)).toEqual(
      ARTIFACT,
    );
    expect(await service.get(ARTIFACT.id, ARTIFACT.version)).toEqual(ARTIFACT);
  });

  it('rejects a file whose bytes are not JSON with a named error (C2)', async () => {
    await place(ARTIFACT.id, ARTIFACT.version, '{ not json');

    const error = await storage
      .readArtifact(ARTIFACT.id, ARTIFACT.version)
      .catch((thrown: unknown) => thrown);

    expect(error).toBeInstanceOf(MalformedReferenceArtifactError);
    expect((error as MalformedReferenceArtifactError).name).toBe(
      'MalformedReferenceArtifactError',
    );
  });

  it('rejects JSON that is not a reference artifact with the same named error (C2)', async () => {
    const notAnArtifact: Record<string, unknown> = { ...ARTIFACT };
    delete notAnArtifact.label;
    await place(ARTIFACT.id, ARTIFACT.version, JSON.stringify(notAnArtifact));

    await expect(
      storage.readArtifact(ARTIFACT.id, ARTIFACT.version),
    ).rejects.toBeInstanceOf(MalformedReferenceArtifactError);
  });

  it('does not serve a malformed file over the service (C2)', async () => {
    await place(ARTIFACT.id, ARTIFACT.version, '{ not json');

    await expect(
      service.get(ARTIFACT.id, ARTIFACT.version),
    ).rejects.toBeInstanceOf(InternalServerErrorException);
  });

  it('still reports not-found for a reference the volume does not hold', async () => {
    await expect(service.get(ARTIFACT.id, '1999.1')).rejects.toThrow();
    expect(await storage.readArtifact(ARTIFACT.id, '1999.1')).toBeNull();
  });
});
