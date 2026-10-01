import { describe, expect, it } from 'vitest';
import { serializeCsv } from '../src/exports/csv.js';
import {
  buildDetectionHistoryMatrix,
  type DetectionHistoryDetection,
  type DetectionHistoryVisit,
} from '../src/exports/detection-history.js';

const det = (
  taxon: string,
  detected: boolean,
  opportunistic = false,
): DetectionHistoryDetection => ({ taxon, detected, opportunistic });

const visit = (
  visitId: string,
  siteId: string,
  surveyPeriodId: string,
  startedAt: string,
  targetTaxonRefs: string[],
  detections: DetectionHistoryDetection[],
): DetectionHistoryVisit => ({
  visitId,
  siteId,
  surveyPeriodId,
  startedAt: new Date(startedAt),
  targetTaxonRefs,
  detections,
});

const csvBytes = (matrix: ReturnType<typeof buildDetectionHistoryMatrix>) =>
  new TextEncoder().encode(serializeCsv([matrix.header, ...matrix.rows]));

describe('detection-history matrix', () => {
  it('writes one row per Visit and one column per TargetList taxonRef (C2)', () => {
    const matrix = buildDetectionHistoryMatrix([
      visit(
        'visit-1',
        'site-1',
        'period-1',
        '2024-01-01T00:00:00.000Z',
        ['B', 'A'],
        [det('B', true), det('A', false)],
      ),
      visit(
        'visit-2',
        'site-2',
        'period-2',
        '2024-02-01T00:00:00.000Z',
        ['A'],
        [det('A', true)],
      ),
    ]);

    expect(matrix.header).toEqual([
      'site_id',
      'survey_period_id',
      'visit_id',
      'started_at',
      'B',
      'A',
    ]);
    expect(matrix.rows).toHaveLength(2);
  });

  it('carries the Site and Survey period identifiers on each row (C3)', () => {
    const matrix = buildDetectionHistoryMatrix([
      visit(
        'visit-1',
        'site-1',
        'period-1',
        '2024-01-01T00:00:00.000Z',
        [],
        [],
      ),
      visit(
        'visit-2',
        'site-2',
        'period-2',
        '2024-02-01T00:00:00.000Z',
        [],
        [],
      ),
    ]);

    expect(matrix.rows[0]!.slice(0, 2)).toEqual(['site-1', 'period-1']);
    expect(matrix.rows[1]!.slice(0, 2)).toEqual(['site-2', 'period-2']);
  });

  it('maps a TargetList taxon Detection to 1 when detected and 0 when not (C4, INV-002)', () => {
    const matrix = buildDetectionHistoryMatrix([
      visit(
        'visit-1',
        'site-1',
        'period-1',
        '2024-01-01T00:00:00.000Z',
        ['B', 'A'],
        [det('B', true), det('A', false)],
      ),
      visit(
        'visit-2',
        'site-2',
        'period-2',
        '2024-02-01T00:00:00.000Z',
        ['A'],
        [det('A', true)],
      ),
    ]);

    const [bIndex, aIndex] = [4, 5];
    expect(matrix.rows[0]![bIndex]).toBe('1');
    expect(matrix.rows[0]![aIndex]).toBe('0');
    expect(matrix.rows[1]![bIndex]).toBe('');
    expect(matrix.rows[1]![aIndex]).toBe('1');
  });

  it('gives an opportunistic Detection no column and never a non-detection (C5, INV-003)', () => {
    const matrix = buildDetectionHistoryMatrix([
      visit(
        'visit-1',
        'site-1',
        'period-1',
        '2024-01-01T00:00:00.000Z',
        ['A'],
        [det('A', true), det('A', false, true), det('X', false, true)],
      ),
    ]);

    expect(matrix.header).toEqual([
      'site_id',
      'survey_period_id',
      'visit_id',
      'started_at',
      'A',
    ]);
    expect(matrix.rows[0]!.slice(4)).toEqual(['1']);
    expect(matrix.rows[0]).not.toContain('0');
  });

  it('orders rows by Site id then Visit startedAt so identical data yields identical bytes (C6)', () => {
    const a = visit(
      'visit-a',
      'site-2',
      'period-1',
      '2024-01-01T00:00:00.000Z',
      ['A'],
      [det('A', true)],
    );
    const b = visit(
      'visit-b',
      'site-1',
      'period-1',
      '2024-03-01T00:00:00.000Z',
      ['A'],
      [det('A', true)],
    );
    const c = visit(
      'visit-c',
      'site-1',
      'period-1',
      '2024-02-01T00:00:00.000Z',
      ['A'],
      [det('A', true)],
    );

    const matrix = buildDetectionHistoryMatrix([a, b, c]);
    expect(matrix.rows.map((row) => row[2])).toEqual([
      'visit-c',
      'visit-b',
      'visit-a',
    ]);

    const tie1 = visit(
      'visit-z',
      'site-1',
      'period-1',
      '2024-01-01T00:00:00.000Z',
      [],
      [],
    );
    const tie2 = visit(
      'visit-a',
      'site-1',
      'period-1',
      '2024-01-01T00:00:00.000Z',
      [],
      [],
    );
    expect(
      buildDetectionHistoryMatrix([tie1, tie2]).rows.map((row) => row[2]),
    ).toEqual(['visit-a', 'visit-z']);

    expect(csvBytes(buildDetectionHistoryMatrix([a, b, c]))).toEqual(
      csvBytes(buildDetectionHistoryMatrix([c, a, b])),
    );
  });
});
