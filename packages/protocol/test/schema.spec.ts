import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Ajv2020 } from 'ajv/dist/2020.js';
import { describe, expect, it } from 'vitest';
import type { ProtocolDocument } from '../src/index.js';

const here = dirname(fileURLToPath(import.meta.url));
const schemaPath = resolve(here, '../schema/protocol.schema.json');
const schema = JSON.parse(readFileSync(schemaPath, 'utf8'));

const targetListSample: ProtocolDocument = {
  protocolId: 'alpine-birds-2026',
  version: 1,
  taxonomicScope: {
    taxa: ['Aves'],
  },
  targetList: [
    { taxonRef: 'Aves|Turdus|merula', label: 'Common blackbird' },
    { taxonRef: 'Aves|Erithacus|rubecula', label: 'European robin' },
  ],
  detectionMethods: [
    { id: 'visual', label: 'Visual detection' },
    { id: 'acoustic', label: 'Acoustic detection' },
  ],
  requiredEffortFields: ['start', 'duration', 'observers', 'detectionMethods'],
  visitCovariates: [
    { name: 'windSpeed', type: 'number', unit: 'm/s' },
    { name: 'weather', type: 'enum', options: ['clear', 'cloudy', 'rain'] },
  ],
  siteCovariates: [{ name: 'habitat', type: 'text' }],
};

const completeListSample: ProtocolDocument = {
  protocolId: 'wetland-plants-2026',
  version: 2,
  taxonomicScope: { taxa: ['Tracheophyta'] },
  detectionMethods: [{ id: 'visual', label: 'Visual detection' }],
  requiredEffortFields: ['start', 'duration', 'observers'],
};

describe('protocol.schema.json', () => {
  const ajv = new Ajv2020({ allErrors: true, strict: true });
  const validate = ajv.compile(schema);

  it('validates a sample protocol document', () => {
    const valid = validate(targetListSample);
    expect(validate.errors).toBeNull();
    expect(valid).toBe(true);
  });

  it('validates a complete-list protocol document with no target list', () => {
    expect(validate(completeListSample)).toBe(true);
  });

  it('rejects a protocol document without a detection method', () => {
    expect(validate({ ...targetListSample, detectionMethods: [] })).toBe(false);
  });

  it('rejects a protocol document missing its taxonomic scope', () => {
    const withoutScope = { ...targetListSample } as Record<string, unknown>;
    delete withoutScope.taxonomicScope;
    expect(validate(withoutScope)).toBe(false);
  });

  it('rejects an enum covariate with no allowed options', () => {
    const invalid = {
      ...targetListSample,
      visitCovariates: [{ name: 'weather', type: 'enum' }],
    };
    expect(validate(invalid)).toBe(false);
  });
});
