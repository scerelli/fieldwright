import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import {
  BadRequestException,
  Module,
  type INestApplication,
} from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { eq, sql } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import {
  detection,
  determination,
  evidence,
  measurement,
  project,
  protocolVersion,
  site,
  surveyPeriod,
  visit,
  type MeasurementProvenance,
} from '../src/db/schema.js';
import { VisitsModule } from '../src/visits/visits.module.js';
import { VisitsService } from '../src/visits/visits.service.js';

const serverRoot = fileURLToPath(new URL('..', import.meta.url));
const drizzleKitBin = fileURLToPath(
  new URL('../node_modules/drizzle-kit/bin.cjs', import.meta.url),
);

function runDrizzleKitMigrate(databaseUrl: string) {
  return spawnSync(process.execPath, [drizzleKitBin, 'migrate'], {
    cwd: serverRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    encoding: 'utf8',
  });
}

@Module({
  imports: [VisitsModule, DatabaseModule],
})
class TestModule {}

interface SeedReferences {
  projectId: string;
  siteId: string;
  surveyPeriodId: string;
  protocolVersionId: string;
}

describe('Visit store', () => {
  let container: StartedPostgreSqlContainer;
  let databaseUrl: string;
  let app: INestApplication;
  let db: NodePgDatabase;
  let visits: VisitsService;

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    databaseUrl = container.getConnectionUri();
    process.env.DATABASE_URL = databaseUrl;

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
    await app.init();
    db = app.get<NodePgDatabase>(DATABASE);
    visits = app.get(VisitsService);
  }, 180_000);

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await container?.stop();
  });

  async function seedReferences(): Promise<SeedReferences> {
    const [createdProject] = await db
      .insert(project)
      .values({
        name: 'Visit store project',
        settings: { validationEnabled: true, sensitiveTaxaObfuscation: false },
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
      })
      .returning();

    const [createdSite] = await db
      .insert(site)
      .values({
        projectId: createdProject.id,
        name: 'Plot A',
        geom: JSON.stringify({ type: 'Point', coordinates: [11.1, 46.1] }),
      })
      .returning();

    const [createdPeriod] = await db
      .insert(surveyPeriod)
      .values({
        projectId: createdProject.id,
        name: 'Spring 2026',
        startDate: '2026-03-01',
        endDate: '2026-05-31',
      })
      .returning();

    const [createdProtocol] = await db
      .insert(protocolVersion)
      .values({
        projectId: createdProject.id,
        protocolId: 'standard',
        version: 1,
        document: { protocolId: 'standard', version: 1 },
      })
      .returning();

    return {
      projectId: createdProject.id,
      siteId: createdSite.id,
      surveyPeriodId: createdPeriod.id,
      protocolVersionId: createdProtocol.id,
    };
  }

  it('stores a submitted Visit with its Detections, Measurements and Evidence', async () => {
    const refs = await seedReferences();
    const id = randomUUID();
    const startedAt = new Date('2026-04-01T08:00:00Z');
    const endedAt = new Date('2026-04-01T09:00:00Z');
    const submittedAt = new Date('2026-04-01T09:05:00Z');

    const stored = await visits.storeSubmittedVisit({
      id,
      ...refs,
      effort: {
        durationMinutes: 60,
        observers: ['A. Collector'],
        detectionMethods: ['visual'],
      },
      startedAt,
      endedAt,
      submittedAt,
      detections: [
        {
          taxon: 'Anthus trivialis',
          detected: true,
          method: 'visual',
          count: 3,
        },
        { taxon: 'Sylvia borin', detected: false, method: 'audio' },
        {
          taxon: 'Vulpes vulpes',
          detected: true,
          method: 'visual',
          opportunistic: true,
        },
      ],
      measurements: [
        {
          value: '12',
          unit: 'celsius',
          provenance: { method: 'field_instrument', device: 'thermo-1' },
        },
        {
          detectionIndex: 0,
          value: '3',
          unit: 'count',
          provenance: { method: 'visual_estimate' },
        },
      ],
      evidence: [
        {
          detectionIndex: 0,
          kind: 'photo',
          storageKey: 'evidences/abc.jpg',
          sha256: 'abc123',
        },
        {
          kind: 'audio',
          storageKey: 'evidences/def.wav',
          sha256: 'def456',
        },
      ],
    });

    expect(stored.state).toBe('submitted');
    expect(stored.siteId).toBe(refs.siteId);
    expect(stored.surveyPeriodId).toBe(refs.surveyPeriodId);
    expect(stored.protocolVersionId).toBe(refs.protocolVersionId);

    const visitRows = await db.select().from(visit).where(eq(visit.id, id));
    expect(visitRows).toHaveLength(1);
    const storedVisit = visitRows[0]!;
    expect(storedVisit.projectId).toBe(refs.projectId);
    expect(storedVisit.siteId).toBe(refs.siteId);
    expect(storedVisit.surveyPeriodId).toBe(refs.surveyPeriodId);
    expect(storedVisit.protocolVersionId).toBe(refs.protocolVersionId);
    expect(storedVisit.state).toBe('submitted');
    expect(storedVisit.submittedAt.toISOString()).toBe(
      submittedAt.toISOString(),
    );

    const detections = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    expect(detections).toHaveLength(3);
    const byTaxon = Object.fromEntries(
      detections.map((row) => [row.taxon, row]),
    );
    expect(byTaxon['Anthus trivialis']!.detected).toBe(true);
    expect(byTaxon['Anthus trivialis']!.count).toBe(3);
    expect(byTaxon['Sylvia borin']!.detected).toBe(false);
    expect(byTaxon['Sylvia borin']!.count).toBeNull();
    expect(byTaxon['Vulpes vulpes']!.opportunistic).toBe(true);

    const measurements = await db
      .select()
      .from(measurement)
      .where(eq(measurement.visitId, id));
    expect(measurements).toHaveLength(2);
    const visitMeasurement = measurements.find(
      (row) => row.detectionId === null,
    )!;
    expect(visitMeasurement.value).toBe('12');
    expect(visitMeasurement.unit).toBe('celsius');
    expect(visitMeasurement.provenance).toMatchObject({
      method: 'field_instrument',
    });
    const detectionMeasurement = measurements.find(
      (row) => row.detectionId !== null,
    )!;
    expect(detectionMeasurement.detectionId).toBe(
      byTaxon['Anthus trivialis']!.id,
    );

    const evidenceRows = await db
      .select()
      .from(evidence)
      .where(eq(evidence.visitId, id));
    expect(evidenceRows).toHaveLength(2);
    const photo = evidenceRows.find((row) => row.kind === 'photo')!;
    expect(photo.storageKey).toBe('evidences/abc.jpg');
    expect(photo.sha256).toBe('abc123');
    expect(photo.detectionId).toBe(byTaxon['Anthus trivialis']!.id);
    const audio = evidenceRows.find((row) => row.kind === 'audio')!;
    expect(audio.detectionId).toBeNull();
  });

  it('enforces exactly one Site, Survey period and Protocol version by foreign key', async () => {
    const refs = await seedReferences();
    const bogus = randomUUID();

    for (const badReference of [
      { siteId: bogus },
      { surveyPeriodId: bogus },
      { protocolVersionId: bogus },
    ]) {
      const id = randomUUID();

      await expect(
        visits.storeSubmittedVisit({
          id,
          ...refs,
          ...badReference,
          effort: {},
          startedAt: new Date('2026-04-01T08:00:00Z'),
          submittedAt: new Date('2026-04-01T09:00:00Z'),
        }),
      ).rejects.toThrow();

      expect(
        await db.select().from(visit).where(eq(visit.id, id)),
      ).toHaveLength(0);
    }
  });

  it('rejects a Measurement with no provenance method and stores no part of the Visit', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    await expect(
      visits.storeSubmittedVisit({
        id,
        ...refs,
        effort: {},
        startedAt: new Date('2026-04-01T08:00:00Z'),
        submittedAt: new Date('2026-04-01T09:00:00Z'),
        detections: [
          { taxon: 'Anthus trivialis', detected: true, method: 'visual' },
        ],
        measurements: [
          {
            value: '5',
            unit: 'count',
            provenance: {} as MeasurementProvenance,
          },
        ],
      }),
    ).rejects.toThrow();

    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
    expect(
      await db.select().from(detection).where(eq(detection.visitId, id)),
    ).toHaveLength(0);
  });

  it('rejects a negative Detection count and stores nothing', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    await expect(
      visits.storeSubmittedVisit({
        id,
        ...refs,
        effort: {},
        startedAt: new Date('2026-04-01T08:00:00Z'),
        submittedAt: new Date('2026-04-01T09:00:00Z'),
        detections: [
          {
            taxon: 'Anthus trivialis',
            detected: false,
            method: 'visual',
            count: -1,
          },
        ],
      }),
    ).rejects.toThrow();

    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
  });

  it('rejects a Measurement whose detectionIndex is out of range and stores nothing', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    await expect(
      visits.storeSubmittedVisit({
        id,
        ...refs,
        effort: {},
        startedAt: new Date('2026-04-01T08:00:00Z'),
        submittedAt: new Date('2026-04-01T09:00:00Z'),
        detections: [
          { taxon: 'Anthus trivialis', detected: true, method: 'visual' },
        ],
        measurements: [
          {
            detectionIndex: 1,
            value: '3',
            unit: 'count',
            provenance: { method: 'visual_estimate' },
          },
        ],
      }),
    ).rejects.toThrow(BadRequestException);

    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
    expect(
      await db.select().from(measurement).where(eq(measurement.visitId, id)),
    ).toHaveLength(0);
  });

  it('rejects Evidence whose detectionIndex is out of range and stores nothing', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    await expect(
      visits.storeSubmittedVisit({
        id,
        ...refs,
        effort: {},
        startedAt: new Date('2026-04-01T08:00:00Z'),
        submittedAt: new Date('2026-04-01T09:00:00Z'),
        detections: [
          { taxon: 'Anthus trivialis', detected: true, method: 'visual' },
        ],
        evidence: [
          {
            detectionIndex: 2,
            kind: 'photo',
            storageKey: 'evidences/abc.jpg',
            sha256: 'abc123',
          },
        ],
      }),
    ).rejects.toThrow(BadRequestException);

    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
    expect(
      await db.select().from(evidence).where(eq(evidence.visitId, id)),
    ).toHaveLength(0);
  });

  it('stores null/absent detectionIndex at Visit level and an in-range index on its Detection', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    await visits.storeSubmittedVisit({
      id,
      ...refs,
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      submittedAt: new Date('2026-04-01T09:00:00Z'),
      detections: [
        { taxon: 'Anthus trivialis', detected: true, method: 'visual' },
        { taxon: 'Sylvia borin', detected: false, method: 'audio' },
      ],
      measurements: [
        {
          detectionIndex: null,
          value: '12',
          unit: 'celsius',
          provenance: { method: 'field_instrument' },
        },
        {
          detectionIndex: 1,
          value: '2',
          unit: 'count',
          provenance: { method: 'visual_estimate' },
        },
      ],
      evidence: [
        {
          detectionIndex: null,
          kind: 'audio',
          storageKey: 'evidences/def.wav',
          sha256: 'def456',
        },
        {
          detectionIndex: 1,
          kind: 'photo',
          storageKey: 'evidences/abc.jpg',
          sha256: 'abc123',
        },
      ],
    });

    const detections = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    const byTaxon = Object.fromEntries(
      detections.map((row) => [row.taxon, row]),
    );

    const measurements = await db
      .select()
      .from(measurement)
      .where(eq(measurement.visitId, id));
    expect(
      measurements.find((row) => row.unit === 'celsius')!.detectionId,
    ).toBeNull();
    expect(measurements.find((row) => row.unit === 'count')!.detectionId).toBe(
      byTaxon['Sylvia borin']!.id,
    );

    const evidenceRows = await db
      .select()
      .from(evidence)
      .where(eq(evidence.visitId, id));
    expect(
      evidenceRows.find((row) => row.kind === 'audio')!.detectionId,
    ).toBeNull();
    expect(evidenceRows.find((row) => row.kind === 'photo')!.detectionId).toBe(
      byTaxon['Sylvia borin']!.id,
    );
  });

  it('rejects an UPDATE or a DELETE of a submitted Visit row at the database', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    await visits.storeSubmittedVisit({
      id,
      ...refs,
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      endedAt: new Date('2026-04-01T09:00:00Z'),
      submittedAt: new Date('2026-04-01T09:05:00Z'),
    });

    await expect(
      db.execute(sql`update visit set effort = '{}'::jsonb where id = ${id}`),
    ).rejects.toThrow();
    await expect(
      db.execute(sql`delete from visit where id = ${id}`),
    ).rejects.toThrow();

    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      1,
    );
  });

  it('rejects an UPDATE of a stored Determination at the database', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    await visits.storeSubmittedVisit({
      id,
      ...refs,
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      endedAt: new Date('2026-04-01T09:00:00Z'),
      submittedAt: new Date('2026-04-01T09:05:00Z'),
      detections: [
        {
          taxon: 'Anthus trivialis',
          detected: true,
          method: 'visual',
          determinations: [
            {
              taxon: 'Anthus trivialis',
              determiner: 'A. Determiner',
              date: '2026-04-01',
            },
          ],
        },
      ],
    });

    const [storedDetection] = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    const [storedDetermination] = await db
      .select()
      .from(determination)
      .where(eq(determination.detectionId, storedDetection!.id));
    expect(storedDetermination).toBeDefined();

    await expect(
      db.execute(
        sql`update determination set taxon = 'Corvus corax' where id = ${storedDetermination!.id}`,
      ),
    ).rejects.toThrow();

    const rows = await db
      .select()
      .from(determination)
      .where(eq(determination.id, storedDetermination!.id));
    expect(rows[0]!.taxon).toBe('Anthus trivialis');
  });

  it('rejects a Visit whose ended_at or submitted_at precedes started_at at the database', async () => {
    const refs = await seedReferences();
    const startedAt = new Date('2026-04-01T08:00:00Z');
    const beforeStart = new Date('2026-04-01T07:00:00Z');

    await expect(
      db.insert(visit).values({
        id: randomUUID(),
        ...refs,
        state: 'submitted',
        effort: {},
        startedAt,
        endedAt: beforeStart,
        submittedAt: new Date('2026-04-01T09:00:00Z'),
      }),
    ).rejects.toThrow();

    await expect(
      db.insert(visit).values({
        id: randomUUID(),
        ...refs,
        state: 'submitted',
        effort: {},
        startedAt,
        endedAt: null,
        submittedAt: beforeStart,
      }),
    ).rejects.toThrow();

    expect(
      await db.select().from(visit).where(eq(visit.siteId, refs.siteId)),
    ).toHaveLength(0);
  });

  it('rejects a Measurement whose Provenance has no method at the database', async () => {
    const refs = await seedReferences();
    const visitId = randomUUID();
    await db.insert(visit).values({
      id: visitId,
      ...refs,
      state: 'submitted',
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      endedAt: null,
      submittedAt: new Date('2026-04-01T09:00:00Z'),
    });

    const withoutMethod: MeasurementProvenance[] = [
      {} as MeasurementProvenance,
      { method: '' },
      { method: '   ' },
    ];
    for (const provenance of withoutMethod) {
      await expect(
        db
          .insert(measurement)
          .values({ visitId, value: '1', unit: 'count', provenance }),
      ).rejects.toThrow();
    }

    expect(
      await db
        .select()
        .from(measurement)
        .where(eq(measurement.visitId, visitId)),
    ).toHaveLength(0);
  });

  it('applies the Visit schema through a forward-only migration', async () => {
    const tables = await db.execute(
      sql`select table_name from information_schema.tables where table_schema = 'public'`,
    );
    const names = (tables.rows as Array<{ table_name: string }>).map(
      (row) => row.table_name,
    );
    for (const table of [
      'site',
      'visit',
      'detection',
      'measurement',
      'evidence',
      'correction',
    ]) {
      expect(names).toContain(table);
    }

    const applied = () =>
      db.execute(
        sql`select count(*)::int as count from drizzle.__drizzle_migrations`,
      );
    const before = (await applied()).rows;

    const rerun = runDrizzleKitMigrate(databaseUrl);
    expect(rerun.status, rerun.stderr).toBe(0);

    expect((await applied()).rows).toEqual(before);
  });
});
