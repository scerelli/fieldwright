import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
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
  correction,
  detection,
  determination,
  evidence,
  measurement,
  membership,
  project,
  protocolVersion,
  site,
  surveyPeriod,
  user,
  visit,
  type MeasurementProvenance,
} from '../src/db/schema.js';
import { VisitsModule } from '../src/visits/visits.module.js';
import {
  VisitsService,
  type StoreDetectionInput,
} from '../src/visits/visits.service.js';

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

interface JournalEntry {
  tag: string;
  when: number;
}

const journal = JSON.parse(
  readFileSync(
    fileURLToPath(new URL('../drizzle/meta/_journal.json', import.meta.url)),
    'utf8',
  ),
) as { entries: JournalEntry[] };

// The `created_at` drizzle-kit writes for a migration is its journal `when`;
// matching on it lets a test un-record exactly one migration so `migrate`
// re-applies it.
function migrationTimestamp(tag: string): number {
  const entry = journal.entries.find((candidate) => candidate.tag === tag);
  if (entry === undefined) {
    throw new Error(`migration ${tag} is not in the drizzle journal`);
  }
  return entry.when;
}

// drizzle wraps a driver error in a DrizzleQueryError whose `cause` is the
// original `pg` error, which carries the Postgres SQLSTATE on `code`.
function sqlStateOf(error: unknown): unknown {
  let current: unknown = error;
  while (current instanceof Error) {
    const code = (current as { code?: unknown }).code;
    if (typeof code === 'string') {
      return code;
    }
    current = (current as { cause?: unknown }).cause;
  }
  return undefined;
}

// Asserts the database refused the statement with `restrict_violation`
// (SQLSTATE 23001), not merely that it failed for any reason.
async function expectRestrictViolation(
  run: () => Promise<unknown>,
): Promise<void> {
  let thrown: unknown;
  try {
    await run();
  } catch (error) {
    thrown = error;
  }
  expect(thrown, 'expected the database to reject the mutation').toBeDefined();
  expect(sqlStateOf(thrown)).toBe('23001');
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

  async function seedReferences(
    taxonomicReference: { id: string | null; version: string | null } = {
      id: 'italy-vascular-flora',
      version: '2024.1',
    },
  ): Promise<SeedReferences> {
    const [createdProject] = await db
      .insert(project)
      .values({
        name: 'Visit store project',
        settings: { validationEnabled: true, sensitiveTaxaObfuscation: false },
        taxonomicReferenceId: taxonomicReference.id,
        taxonomicReferenceVersion: taxonomicReference.version,
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

  async function seedPerson(): Promise<{ id: string }> {
    const [created] = await db
      .insert(user)
      .values({
        id: randomUUID(),
        name: 'V. Validator',
        email: `validator-${randomUUID()}@example.com`,
      })
      .returning();
    return { id: created.id };
  }

  async function storeSubmittedVisit(refs: SeedReferences): Promise<string> {
    const id = randomUUID();
    await visits.storeSubmittedVisit({
      id,
      ...refs,
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      endedAt: new Date('2026-04-01T09:00:00Z'),
      submittedAt: new Date('2026-04-01T09:05:00Z'),
    });
    return id;
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

  it('records the Project pin even when the Visit has no Protocol version or Survey period (INV-021)', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    const stored = await visits.storeSubmittedVisit({
      id,
      projectId: refs.projectId,
      siteId: refs.siteId,
      surveyPeriodId: null,
      protocolVersionId: null,
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      submittedAt: new Date('2026-04-01T09:00:00Z'),
    });

    const [owner] = await db
      .select()
      .from(project)
      .where(eq(project.id, refs.projectId));
    expect(stored.surveyPeriodId).toBeNull();
    expect(stored.protocolVersionId).toBeNull();
    expect(stored.taxonomicReferenceId).toBe(owner!.taxonomicReferenceId);
    expect(stored.taxonomicReferenceVersion).toBe(
      owner!.taxonomicReferenceVersion,
    );
  });

  it('accepts and stores a Visit with provisional Detections for a Project with no pinned Taxonomic reference (INV-022)', async () => {
    const refs = await seedReferences({ id: null, version: null });
    const id = randomUUID();

    const stored = await visits.storeSubmittedVisit({
      id,
      ...refs,
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      submittedAt: new Date('2026-04-01T09:00:00Z'),
      detections: [
        { provisionalName: 'cf. Anthus', detected: true, method: 'visual' },
      ],
    });

    expect(stored.taxonomicReferenceId).toBeNull();
    expect(stored.taxonomicReferenceVersion).toBeNull();
    const [storedDetection] = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    expect(storedDetection!.taxon).toBeNull();
    expect(storedDetection!.provisionalName).toBe('cf. Anthus');
  });

  it('rejects a resolved Detection for a Project with no pinned reference (INV-021)', async () => {
    const refs = await seedReferences({ id: null, version: null });
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
      }),
    ).rejects.toThrow(BadRequestException);

    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
  });

  it('stores a Detection carrying only a provisionalName and no resolved taxon (INV-021)', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    await visits.storeSubmittedVisit({
      id,
      ...refs,
      effort: {},
      startedAt: new Date('2026-04-01T08:00:00Z'),
      submittedAt: new Date('2026-04-01T09:00:00Z'),
      detections: [
        { provisionalName: 'cf. Anthus', detected: true, method: 'visual' },
      ],
    });

    const [stored] = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    expect(stored!.taxon).toBeNull();
    expect(stored!.provisionalName).toBe('cf. Anthus');
    expect(stored!.detected).toBe(true);
  });

  it('rejects a Detection that carries both a taxon and a provisional name, or neither (INV-021)', async () => {
    const refs = await seedReferences();

    const malformed: StoreDetectionInput[] = [
      {
        taxon: 'Anthus trivialis',
        provisionalName: 'cf. Anthus',
        detected: true,
        method: 'visual',
      },
      { detected: true, method: 'visual' },
    ];

    for (const entry of malformed) {
      const id = randomUUID();
      await expect(
        visits.storeSubmittedVisit({
          id,
          ...refs,
          effort: {},
          startedAt: new Date('2026-04-01T08:00:00Z'),
          submittedAt: new Date('2026-04-01T09:00:00Z'),
          detections: [entry],
        }),
      ).rejects.toThrow(BadRequestException);
      expect(
        await db.select().from(visit).where(eq(visit.id, id)),
      ).toHaveLength(0);
    }
  });

  it('rejects a provisional Detection that is not presence-only (INV-021)', async () => {
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
          { provisionalName: 'cf. Anthus', detected: false, method: 'visual' },
        ],
      }),
    ).rejects.toThrow(BadRequestException);

    expect(await db.select().from(visit).where(eq(visit.id, id))).toHaveLength(
      0,
    );
  });

  it('stores a Detection with exactly one of a resolved taxon or a provisional name (INV-021, ADR-0021)', async () => {
    const refs = await seedReferences();
    const id = await storeSubmittedVisit(refs);

    const [resolved] = await db
      .insert(detection)
      .values({
        visitId: id,
        taxon: 'Anthus trivialis',
        detected: true,
        method: 'visual',
      })
      .returning();
    expect(resolved!.taxon).toBe('Anthus trivialis');
    expect(resolved!.provisionalName).toBeNull();

    const [provisional] = await db
      .insert(detection)
      .values({
        visitId: id,
        provisionalName: 'cf. Anthus',
        detected: true,
        method: 'visual',
      })
      .returning();
    expect(provisional!.taxon).toBeNull();
    expect(provisional!.provisionalName).toBe('cf. Anthus');

    await expect(
      db.insert(detection).values({
        visitId: id,
        taxon: 'Sylvia borin',
        provisionalName: 'cf. Sylvia borin',
        detected: true,
        method: 'visual',
      }),
    ).rejects.toThrow();
    await expect(
      db.insert(detection).values({
        visitId: id,
        detected: true,
        method: 'visual',
      }),
    ).rejects.toThrow();

    const rows = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    expect(rows).toHaveLength(2);
  });

  it('rejects a duplicate effective target taxon per Visit for non-opportunistic Detections (INV-003, ADR-0021)', async () => {
    const refs = await seedReferences();
    const id = await storeSubmittedVisit(refs);

    await db.insert(detection).values({
      visitId: id,
      taxon: 'Anthus trivialis',
      detected: true,
      method: 'visual',
    });

    await expect(
      db.insert(detection).values({
        visitId: id,
        taxon: 'Anthus trivialis',
        detected: false,
        method: 'visual',
      }),
    ).rejects.toThrow();

    // A provisional name counts against a resolved taxon of the same name.
    await expect(
      db.insert(detection).values({
        visitId: id,
        provisionalName: 'Anthus trivialis',
        detected: true,
        method: 'visual',
      }),
    ).rejects.toThrow();

    // Opportunistic Detections are not unique per Visit, and a duplicate
    // opportunistic taxon does not collide with the resolved target.
    await db.insert(detection).values({
      visitId: id,
      taxon: 'Vulpes vulpes',
      detected: true,
      method: 'visual',
      opportunistic: true,
    });
    await db.insert(detection).values({
      visitId: id,
      taxon: 'Vulpes vulpes',
      detected: true,
      method: 'visual',
      opportunistic: true,
    });

    const rows = await db
      .select()
      .from(detection)
      .where(eq(detection.visitId, id));
    expect(rows).toHaveLength(3);
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

  it('rejects an UPDATE of a stored Correction at the database (INV-001, INV-013)', async () => {
    const refs = await seedReferences();
    const author = await seedPerson();
    const visitId = await storeSubmittedVisit(refs);

    const [stored] = await db
      .insert(correction)
      .values({
        visitId,
        authorId: author.id,
        reason: 'Anthus trivialis misidentified',
        payload: { taxon: 'Anthus pratensis' },
      })
      .returning();

    await expectRestrictViolation(() =>
      db.execute(
        sql`update correction set reason = 'changed' where id = ${stored!.id}`,
      ),
    );

    const [unchanged] = await db
      .select()
      .from(correction)
      .where(eq(correction.id, stored!.id));
    expect(unchanged!.reason).toBe('Anthus trivialis misidentified');
    expect(unchanged!.payload).toEqual({ taxon: 'Anthus pratensis' });
  });

  it('rejects a DELETE of a stored Correction at the database (INV-001, INV-013)', async () => {
    const refs = await seedReferences();
    const author = await seedPerson();
    const visitId = await storeSubmittedVisit(refs);

    const [stored] = await db
      .insert(correction)
      .values({
        visitId,
        authorId: author.id,
        reason: 'Site recorded in error',
        payload: { note: 'remove' },
      })
      .returning();

    await expectRestrictViolation(() =>
      db.execute(sql`delete from correction where id = ${stored!.id}`),
    );

    const remaining = await db
      .select()
      .from(correction)
      .where(eq(correction.id, stored!.id));
    expect(remaining).toHaveLength(1);
  });

  it('permits a submitted Visit to become validated or rejected, recording the validator and time (INV-013)', async () => {
    const refs = await seedReferences();
    const validator = await seedPerson();

    for (const state of ['validated', 'rejected'] as const) {
      const id = await storeSubmittedVisit(refs);

      await db.execute(
        sql`update visit set state = ${state}, validator_id = ${validator.id}, validated_at = timestamp '2026-04-02 10:00:00' where id = ${id}`,
      );

      const [stored] = await db.select().from(visit).where(eq(visit.id, id));
      expect(stored!.state).toBe(state);
      expect(stored!.validatorId).toBe(validator.id);

      const [recorded] = (
        await db.execute(
          sql`select to_char("validated_at", 'YYYY-MM-DD"T"HH24:MI:SS') as "validated_at" from "visit" where "id" = ${id}`,
        )
      ).rows as Array<{ validated_at: string }>;
      expect(recorded!.validated_at).toBe('2026-04-02T10:00:00');
    }
  });

  it('rejects a Validation that does not record the validator and the time (INV-013)', async () => {
    const refs = await seedReferences();
    const validator = await seedPerson();
    const id = await storeSubmittedVisit(refs);

    await expect(
      db.execute(
        sql`update visit set state = 'validated', validated_at = now() where id = ${id}`,
      ),
    ).rejects.toThrow();
    await expect(
      db.execute(
        sql`update visit set state = 'validated', validator_id = ${validator.id} where id = ${id}`,
      ),
    ).rejects.toThrow();
    await expect(
      db.execute(sql`update visit set state = 'validated' where id = ${id}`),
    ).rejects.toThrow();

    const [stored] = await db.select().from(visit).where(eq(visit.id, id));
    expect(stored!.state).toBe('submitted');
    expect(stored!.validatorId).toBeNull();
    expect(stored!.validatedAt).toBeNull();
  });

  it('rejects an UPDATE of a stored Visit that changes any column but state, validator_id or validated_at (INV-001)', async () => {
    const refs = await seedReferences();
    const validator = await seedPerson();
    const id = await storeSubmittedVisit(refs);

    await expect(
      db.execute(
        sql`update visit set effort = '{"changed":true}'::jsonb where id = ${id}`,
      ),
    ).rejects.toThrow();
    await expect(
      db.execute(sql`update visit set submitted_at = now() where id = ${id}`),
    ).rejects.toThrow();
    await expect(
      db.execute(
        sql`update visit set state = 'validated', validator_id = ${validator.id}, validated_at = now(), effort = '{"changed":true}'::jsonb where id = ${id}`,
      ),
    ).rejects.toThrow();

    const [stored] = await db.select().from(visit).where(eq(visit.id, id));
    expect(stored!.state).toBe('submitted');
    expect(stored!.effort).toEqual({});
  });

  it('rejects an UPDATE of a validated or rejected Visit (INV-013)', async () => {
    const refs = await seedReferences();
    const validator = await seedPerson();

    for (const state of ['validated', 'rejected'] as const) {
      const id = await storeSubmittedVisit(refs);
      await db.execute(
        sql`update visit set state = ${state}, validator_id = ${validator.id}, validated_at = now() where id = ${id}`,
      );

      await expect(
        db.execute(sql`update visit set state = 'rejected' where id = ${id}`),
      ).rejects.toThrow();
      await expect(
        db.execute(
          sql`update visit set validator_id = ${validator.id} where id = ${id}`,
        ),
      ).rejects.toThrow();

      const [stored] = await db.select().from(visit).where(eq(visit.id, id));
      expect(stored!.state).toBe(state);
    }
  });

  it('rejects a DELETE of a submitted, validated or rejected Visit (INV-013)', async () => {
    const refs = await seedReferences();
    const validator = await seedPerson();

    const submitted = await storeSubmittedVisit(refs);
    const validated = await storeSubmittedVisit(refs);
    await db.execute(
      sql`update visit set state = 'validated', validator_id = ${validator.id}, validated_at = now() where id = ${validated}`,
    );
    const rejected = await storeSubmittedVisit(refs);
    await db.execute(
      sql`update visit set state = 'rejected', validator_id = ${validator.id}, validated_at = now() where id = ${rejected}`,
    );

    for (const id of [submitted, validated, rejected]) {
      await expect(
        db.execute(sql`delete from visit where id = ${id}`),
      ).rejects.toThrow();
    }

    const remaining = await db.select().from(visit);
    expect(remaining.map((row) => row.id)).toEqual(
      expect.arrayContaining([submitted, validated, rejected]),
    );
  });

  it('rejects a Visit whose ended_at or submitted_at precedes started_at at the database', async () => {
    const refs = await seedReferences();
    const startedAt = new Date('2026-04-01T08:00:00Z');
    const beforeStart = new Date('2026-04-01T07:00:00Z');

    await expect(
      db.insert(visit).values({
        id: randomUUID(),
        ...refs,
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
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
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
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
      taxonomicReferenceId: 'italy-vascular-flora',
      taxonomicReferenceVersion: '2024.1',
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

  it('backfills the pinned Taxonomic reference on a database that already holds a Visit when the migration applies (INV-008)', async () => {
    const refs = await seedReferences();
    const id = randomUUID();

    // 0011 predates Story #366's nullable Project pin, so a faithful pre-0011
    // database has a pin on every Project; back-fill any pin left null by a
    // later test so the migration's `SET NOT NULL` backfill can hold.
    await db.execute(
      sql`update "project" set "taxonomic_reference_id" = 'italy-vascular-flora', "taxonomic_reference_version" = '2024.1' where "taxonomic_reference_id" is null`,
    );

    // Reproduce a database on the pre-0011 schema that already holds a
    // submitted Visit: drop the columns the migration adds, and un-record the
    // migration (and every later one, since drizzle re-applies from a
    // high-water mark) so they are pending again.
    await db.execute(
      sql`alter table "visit" drop column "taxonomic_reference_id", drop column "taxonomic_reference_version", drop column "validator_id", drop column "validated_at"`,
    );
    await db.execute(
      sql`delete from drizzle.__drizzle_migrations where created_at >= ${migrationTimestamp('0011_low_roland_deschain')}`,
    );
    await db.execute(sql`
      insert into "visit"
        ("id", "project_id", "site_id", "survey_period_id", "protocol_version_id", "state", "effort", "started_at", "submitted_at")
      values
        (${id}, ${refs.projectId}, ${refs.siteId}, ${refs.surveyPeriodId}, ${refs.protocolVersionId}, 'submitted', '{}'::jsonb, now(), now())
    `);

    const migration = runDrizzleKitMigrate(databaseUrl);
    expect(migration.status, migration.stderr + migration.stdout).toBe(0);

    const [stored] = await db.select().from(visit).where(eq(visit.id, id));
    const [owner] = await db
      .select()
      .from(project)
      .where(eq(project.id, refs.projectId));
    expect(stored!.taxonomicReferenceId).toBe(owner!.taxonomicReferenceId);
    expect(stored!.taxonomicReferenceVersion).toBe(
      owner!.taxonomicReferenceVersion,
    );
  });

  it('adds the Visit Validation columns on a database that already holds a submitted Visit (INV-013)', async () => {
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

    // Reproduce a database on the pre-0012 schema that already holds a
    // submitted Visit: drop the columns the migration adds, and un-record it
    // (and every later migration, since drizzle re-applies from a high-water
    // mark) so it is pending again.
    await db.execute(
      sql`alter table "visit" drop column "validator_id", drop column "validated_at"`,
    );
    await db.execute(
      sql`delete from drizzle.__drizzle_migrations where created_at >= ${migrationTimestamp('0012_visit_validation_columns')}`,
    );

    const migration = runDrizzleKitMigrate(databaseUrl);
    expect(migration.status, migration.stderr + migration.stdout).toBe(0);

    const [stored] = await db.select().from(visit).where(eq(visit.id, id));
    expect(stored).toBeDefined();
    expect(stored!.state).toBe('submitted');
    expect(stored!.validatorId).toBeNull();
    expect(stored!.validatedAt).toBeNull();
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

  describe('analysis-readiness derivation (INV-019 – INV-022)', () => {
    const startedAt = new Date('2026-04-01T08:00:00Z');
    const submittedAt = new Date('2026-04-01T09:00:00Z');

    async function seedProtocol(
      projectId: string,
      document: Record<string, unknown>,
    ): Promise<string> {
      const [created] = await db
        .insert(protocolVersion)
        .values({ projectId, protocolId: randomUUID(), version: 1, document })
        .returning();
      return created.id;
    }

    it('is analysis-ready with the Project pin, a Survey period and Protocol version, every target recorded and no provisional Detection (INV-020 – INV-022)', async () => {
      const refs = await seedReferences();
      const protocolVersionId = await seedProtocol(refs.projectId, {
        targetList: [
          { taxonRef: 'Anthus trivialis' },
          { taxonRef: 'Sylvia borin' },
        ],
      });
      const id = randomUUID();

      await visits.storeSubmittedVisit({
        id,
        projectId: refs.projectId,
        siteId: refs.siteId,
        surveyPeriodId: refs.surveyPeriodId,
        protocolVersionId,
        effort: {},
        startedAt,
        submittedAt,
        detections: [
          { taxon: 'Anthus trivialis', detected: true, method: 'visual' },
          { taxon: 'Sylvia borin', detected: false, method: 'audio' },
        ],
      });

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(id)).toBe(true);
    });

    it('is not analysis-ready when the Project has no pinned Taxonomic reference (INV-021, INV-022)', async () => {
      const refs = await seedReferences({ id: null, version: null });
      const id = randomUUID();

      await visits.storeSubmittedVisit({
        id,
        ...refs,
        effort: {},
        startedAt,
        submittedAt,
        detections: [
          { provisionalName: 'cf. Anthus', detected: true, method: 'visual' },
        ],
      });

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(id)).toBe(false);
    });

    it('is not analysis-ready when the Visit has no Survey period (INV-020, INV-022)', async () => {
      const refs = await seedReferences();
      const id = randomUUID();

      await visits.storeSubmittedVisit({
        id,
        projectId: refs.projectId,
        siteId: refs.siteId,
        surveyPeriodId: null,
        protocolVersionId: refs.protocolVersionId,
        effort: {},
        startedAt,
        submittedAt,
      });

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(id)).toBe(false);
    });

    it('is not analysis-ready when the Visit has no Protocol version (INV-020, INV-022)', async () => {
      const refs = await seedReferences();
      const id = randomUUID();

      await visits.storeSubmittedVisit({
        id,
        projectId: refs.projectId,
        siteId: refs.siteId,
        surveyPeriodId: refs.surveyPeriodId,
        protocolVersionId: null,
        effort: {},
        startedAt,
        submittedAt,
      });

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(id)).toBe(false);
    });

    it('is not analysis-ready when a Detection is provisional (INV-021, INV-022)', async () => {
      const refs = await seedReferences();
      const id = randomUUID();

      await visits.storeSubmittedVisit({
        id,
        ...refs,
        effort: {},
        startedAt,
        submittedAt,
        detections: [
          { provisionalName: 'cf. Anthus', detected: true, method: 'visual' },
        ],
      });

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(id)).toBe(false);
    });

    it('is not analysis-ready when a target taxon is not recorded (INV-019, INV-022)', async () => {
      const refs = await seedReferences();
      const protocolVersionId = await seedProtocol(refs.projectId, {
        targetList: [
          { taxonRef: 'Anthus trivialis' },
          { taxonRef: 'Sylvia borin' },
        ],
      });
      const id = randomUUID();

      await visits.storeSubmittedVisit({
        id,
        projectId: refs.projectId,
        siteId: refs.siteId,
        surveyPeriodId: refs.surveyPeriodId,
        protocolVersionId,
        effort: {},
        startedAt,
        submittedAt,
        detections: [
          { taxon: 'Anthus trivialis', detected: true, method: 'visual' },
        ],
      });

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(id)).toBe(false);
    });

    it('is not analysis-ready when a required Sampling-effort field is not recorded (INV-005)', async () => {
      const refs = await seedReferences();
      const protocolVersionId = await seedProtocol(refs.projectId, {
        requiredEffortFields: ['durationMinutes'],
      });
      const id = randomUUID();

      await visits.storeSubmittedVisit({
        id,
        projectId: refs.projectId,
        siteId: refs.siteId,
        surveyPeriodId: refs.surveyPeriodId,
        protocolVersionId,
        effort: {},
        startedAt,
        submittedAt,
      });

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(id)).toBe(false);
    });

    async function seedCollector(projectId: string): Promise<{ id: string }> {
      const author = await seedPerson();
      await db.insert(membership).values({
        personId: author.id,
        projectId,
        role: 'collector',
      });
      return author;
    }

    const resolutionPayload = {
      kind: 'resolution',
      taxonomicReferenceVersion: '2024.1',
      resolvedTaxa: [
        { provisionalName: 'cf. Anthus', taxon: 'Anthus trivialis' },
      ],
    };

    async function storeProvisionalVisit(
      refs: SeedReferences,
      protocolVersionId: string,
      id: string,
    ): Promise<void> {
      await visits.storeSubmittedVisit({
        id,
        projectId: refs.projectId,
        siteId: refs.siteId,
        surveyPeriodId: refs.surveyPeriodId,
        protocolVersionId,
        effort: {},
        startedAt,
        submittedAt,
        detections: [
          { provisionalName: 'cf. Anthus', detected: true, method: 'visual' },
        ],
      });
    }

    it('leaves the stored Visit and Detection rows unchanged when a resolution Correction is applied (INV-001)', async () => {
      const refs = await seedReferences();
      const protocolVersionId = await seedProtocol(refs.projectId, {
        targetList: [{ taxonRef: 'Anthus trivialis' }],
      });
      const author = await seedCollector(refs.projectId);
      const id = randomUUID();
      await storeProvisionalVisit(refs, protocolVersionId, id);

      const [visitBefore] = await db
        .select()
        .from(visit)
        .where(eq(visit.id, id));
      const detectionsBefore = await db
        .select()
        .from(detection)
        .where(eq(detection.visitId, id))
        .orderBy(detection.id);

      await visits.recordCorrection(author.id, id, {
        reason: 'resolve cf. Anthus',
        payload: resolutionPayload,
      });
      await visits.analysisReadyVisitIds(refs.projectId);

      const [visitAfter] = await db
        .select()
        .from(visit)
        .where(eq(visit.id, id));
      const detectionsAfter = await db
        .select()
        .from(detection)
        .where(eq(detection.visitId, id))
        .orderBy(detection.id);
      expect(visitAfter).toEqual(visitBefore);
      expect(detectionsAfter).toEqual(detectionsBefore);
    });

    it('becomes analysis-ready once a resolution Correction is applied, and then enters exports (INV-021, INV-022)', async () => {
      const refs = await seedReferences();
      const protocolVersionId = await seedProtocol(refs.projectId, {
        targetList: [{ taxonRef: 'Anthus trivialis' }],
      });
      const author = await seedCollector(refs.projectId);
      const id = randomUUID();
      await storeProvisionalVisit(refs, protocolVersionId, id);

      expect((await visits.analysisReadyVisitIds(refs.projectId)).has(id)).toBe(
        false,
      );

      await visits.recordCorrection(author.id, id, {
        reason: 'resolve cf. Anthus',
        payload: resolutionPayload,
      });

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(id)).toBe(true);
    });

    it('re-derives the same analysis-readiness from an applied resolution Correction (idempotent, INV-001)', async () => {
      const refs = await seedReferences();
      const protocolVersionId = await seedProtocol(refs.projectId, {
        targetList: [{ taxonRef: 'Anthus trivialis' }],
      });
      const author = await seedCollector(refs.projectId);
      const id = randomUUID();
      await storeProvisionalVisit(refs, protocolVersionId, id);
      await visits.recordCorrection(author.id, id, {
        reason: 'resolve cf. Anthus',
        payload: resolutionPayload,
      });

      const first = await visits.analysisReadyVisitIds(refs.projectId);
      const second = await visits.analysisReadyVisitIds(refs.projectId);
      expect(first.has(id)).toBe(true);
      expect([...second].sort()).toEqual([...first].sort());
    });

    it('applies resolution Corrections in recorded order, the latest assignment winning (INV-021)', async () => {
      const refs = await seedReferences();
      const protocolVersionId = await seedProtocol(refs.projectId, {
        targetList: [{ taxonRef: 'Anthus trivialis' }],
      });
      const author = await seedCollector(refs.projectId);

      const firstOnly = randomUUID();
      await storeProvisionalVisit(refs, protocolVersionId, firstOnly);
      await db.insert(correction).values({
        visitId: firstOnly,
        authorId: author.id,
        reason: 'resolution',
        payload: resolutionPayload,
        createdAt: new Date('2026-05-01T00:00:00Z'),
      });

      const superseded = randomUUID();
      await storeProvisionalVisit(refs, protocolVersionId, superseded);
      await db.insert(correction).values([
        {
          visitId: superseded,
          authorId: author.id,
          reason: 'first resolution',
          payload: resolutionPayload,
          createdAt: new Date('2026-05-01T00:00:00Z'),
        },
        {
          visitId: superseded,
          authorId: author.id,
          reason: 'second resolution',
          payload: {
            kind: 'resolution',
            taxonomicReferenceVersion: '2024.1',
            resolvedTaxa: [
              { provisionalName: 'cf. Anthus', taxon: 'Anthus pratensis' },
            ],
          },
          createdAt: new Date('2026-05-01T00:01:00Z'),
        },
      ]);

      const ready = await visits.analysisReadyVisitIds(refs.projectId);
      expect(ready.has(firstOnly)).toBe(true);
      expect(ready.has(superseded)).toBe(false);
    });
  });
});
