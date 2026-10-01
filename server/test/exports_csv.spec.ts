import { describe, expect, it } from 'vitest';
import { escapeCsvField, serializeCsv } from '../src/exports/csv.js';

describe('CSV serializer (RFC 4180)', () => {
  it('leaves a field with no comma, double quote or newline unquoted (C1)', () => {
    expect(escapeCsvField('Turdus merula')).toBe('Turdus merula');
    expect(escapeCsvField('')).toBe('');
  });

  it('quotes a field containing a comma (C1)', () => {
    expect(escapeCsvField('Lazio, Italy')).toBe('"Lazio, Italy"');
  });

  it('quotes a field containing a double quote and doubles the quote (C1)', () => {
    expect(escapeCsvField('say "merula"')).toBe('"say ""merula"""');
  });

  it('quotes a field containing a newline (C1)', () => {
    expect(escapeCsvField('first\nsecond')).toBe('"first\nsecond"');
    expect(escapeCsvField('first\r\nsecond')).toBe('"first\r\nsecond"');
  });

  it('serializes rows with comma-separated fields and CRLF-terminated records (C1)', () => {
    const csv = serializeCsv([
      ['site_id', 'taxon'],
      ['s-1', 'Lazio, Italy'],
    ]);
    expect(csv).toBe('site_id,taxon\r\ns-1,"Lazio, Italy"');
  });

  it('produces identical text for identical rows (C1)', () => {
    const rows = [
      ['a,b', 'c"d'],
      ['e\nf', 'g'],
    ];
    expect(serializeCsv(rows)).toBe(serializeCsv(rows));
  });
});
