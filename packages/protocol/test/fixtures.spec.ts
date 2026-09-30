import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Ajv2020 } from 'ajv/dist/2020.js';
import { describe, expect, it } from 'vitest';
import type { ProtocolDocument } from '../src/index.js';

const here = dirname(fileURLToPath(import.meta.url));
const schemaPath = resolve(here, '../schema/protocol.schema.json');
const fixturePath = resolve(here, '../fixtures/protocol.example.json');
const schema = JSON.parse(readFileSync(schemaPath, 'utf8'));

describe('protocol.example.json', () => {
  const ajv = new Ajv2020({ allErrors: true, strict: true });
  const validate = ajv.compile(schema);

  it('validates against protocol.schema.json', () => {
    const fixture = JSON.parse(
      readFileSync(fixturePath, 'utf8'),
    ) as ProtocolDocument;

    const valid = validate(fixture);
    expect(validate.errors).toBeNull();
    expect(valid).toBe(true);
  });
});
