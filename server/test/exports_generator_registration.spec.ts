import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import {
  Injectable,
  Module,
  type INestApplicationContext,
} from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { DatabaseModule } from '../src/db/database.module.js';
import { DATABASE, DATABASE_POOL } from '../src/db/database.provider.js';
import {
  detection,
  exportRecord,
  project,
  protocolVersion,
  site,
  surveyPeriod,
  visit,
} from '../src/db/schema.js';
import {
  buildDetectionHistoryMatrix,
  type DetectionHistoryVisit,
} from '../src/exports/detection-history.js';
import {
  DETECTION_HISTORY_BUILDER,
  DetectionHistoryGenerator,
  type DetectionHistoryBuilder,
} from '../src/exports/detection-history.generator.js';
import {
  EXPORT_GENERATORS,
  ExportGeneratorRegistry,
  type ExportGenerator,
} from '../src/exports/export.processor.js';
import { exportGeneratorsFactory } from '../src/exports/exports.module.js';

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

/**
 * A stand-in for a sibling format generator (#47–#49 register the real ones):
 * it proves the factory returns every injected generator, not just the `csv`
 * one, without depending on another format's implementation.
 */
@Injectable()
class FakeSiblingGenerator implements ExportGenerator {
  readonly format = 'darwin_core';

  async generate(): Promise<Uint8Array> {
    return new Uint8Array();
  }
}

/** Records every matrix input the generator passes to the injected builder. */
let builderCalls: DetectionHistoryVisit[][] = [];
const builderSpy: DetectionHistoryBuilder = (visits) => {
  builderCalls.push([...visits]);
  return buildDetectionHistoryMatrix(visits);
};

@Module({
  imports: [DatabaseModule],
  providers: [
    DetectionHistoryGenerator,
    FakeSiblingGenerator,
    ExportGeneratorRegistry,
    { provide: DETECTION_HISTORY_BUILDER, useValue: builderSpy },
    {
      provide: EXPORT_GENERATORS,
      useFactory: exportGeneratorsFactory,
      inject: [DetectionHistoryGenerator, FakeSiblingGenerator],
    },
  ],
})
class TestModule {}

describe('exports generator registration', () => {
  let postgres: StartedPostgreSqlContainer;
  let app: INestApplicationContext;
  let db: NodePgDatabase;

  beforeAll(async () => {
    postgres = await new PostgreSqlContainer('postgis/postgis:18-3.6').start();
    process.env.DATABASE_URL = postgres.getConnectionUri();

    const migrate = runDrizzleKitMigrate(process.env.DATABASE_URL!);
    if (migrate.status !== 0) {
      throw new Error(
        `drizzle-kit migrate failed: ${migrate.stderr}${migrate.stdout}`,
      );
    }

    app = await NestFactory.createApplicationContext(TestModule, {
      logger: false,
    });
    db = app.get<NodePgDatabase>(DATABASE);
  }, 240_000);

  beforeEach(() => {
    builderCalls = [];
  });

  afterAll(async () => {
    if (app) {
      const pool = app.get<Pool>(DATABASE_POOL);
      await app.close();
      await pool.end();
    }
    await postgres?.stop();
  });

  async function seedProject(name: string): Promise<{
    projectId: string;
    protocolVersionId: string;
  }> {
    const [created] = await db
      .insert(project)
      .values({
        name,
        settings: { validationEnabled: false, sensitiveTaxaObfuscation: false },
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
      })
      .returning();
    const [protocol] = await db
      .insert(protocolVersion)
      .values({
        projectId: created!.id,
        protocolId: 'standard',
        version: 1,
        document: {
          protocolId: 'standard',
          version: 1,
          targetList: [{ taxonRef: 'B' }, { taxonRef: 'A' }],
        },
      })
      .returning();
    return { projectId: created!.id, protocolVersionId: protocol!.id };
  }

  it('returns every injected generator from the EXPORT_GENERATORS factory so a sibling stays resolvable (C1)', () => {
    const registry = app.get(ExportGeneratorRegistry);

    expect(registry.resolve('csv')).toBeInstanceOf(DetectionHistoryGenerator);
    expect(registry.resolve('darwin_core')).toBeInstanceOf(
      FakeSiblingGenerator,
    );
  });

  it("resolves the csv generator for 'csv' and throws for an unregistered format (C2)", () => {
    const registry = app.get(ExportGeneratorRegistry);

    expect(registry.resolve('csv')).toBeInstanceOf(DetectionHistoryGenerator);
    expect(() => registry.resolve('geopackage')).toThrow(/geopackage/);
  });

  it("generates the Export Project's detection-history CSV bytes through the injected builder (C3)", async () => {
    const site1 = '00000000-0000-0000-0000-000000000001';
    const site2 = '00000000-0000-0000-0000-000000000002';
    const period1 = '00000000-0000-0000-0000-0000000000a1';
    const period2 = '00000000-0000-0000-0000-0000000000a2';
    const visit1 = '00000000-0000-0000-0000-000000000011';
    const visit2 = '00000000-0000-0000-0000-000000000012';

    const { projectId, protocolVersionId } = await seedProject('Main project');
    const other = await seedProject('Other project');

    await db.insert(site).values([
      { id: site1, projectId, name: 'Plot A' },
      { id: site2, projectId, name: 'Plot B' },
    ]);
    await db.insert(surveyPeriod).values([
      {
        id: period1,
        projectId,
        name: 'Spring',
        startDate: '2024-01-01',
        endDate: '2024-03-31',
      },
      {
        id: period2,
        projectId,
        name: 'Summer',
        startDate: '2024-04-01',
        endDate: '2024-06-30',
      },
    ]);
    await db.insert(visit).values([
      {
        id: visit1,
        projectId,
        siteId: site1,
        surveyPeriodId: period1,
        protocolVersionId,
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
        state: 'submitted',
        effort: {},
        startedAt: new Date('2024-01-01T00:00:00.000Z'),
        submittedAt: new Date('2024-01-01T01:00:00.000Z'),
      },
      {
        id: visit2,
        projectId,
        siteId: site2,
        surveyPeriodId: period2,
        protocolVersionId,
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
        state: 'submitted',
        effort: {},
        startedAt: new Date('2024-02-01T00:00:00.000Z'),
        submittedAt: new Date('2024-02-01T01:00:00.000Z'),
      },
    ]);
    await db.insert(detection).values([
      { visitId: visit1, taxon: 'B', detected: true, method: 'visual' },
      { visitId: visit1, taxon: 'A', detected: false, method: 'audio' },
      {
        visitId: visit1,
        taxon: 'X',
        detected: true,
        method: 'visual',
        opportunistic: true,
      },
      { visitId: visit2, taxon: 'A', detected: true, method: 'visual' },
      // visit2 records both Target list taxa, so it stays analysis-ready
      // (INV-022) and remains in the export after #400's readiness gate.
      { visitId: visit2, taxon: 'B', detected: false, method: 'visual' },
    ]);

    const [otherSite] = await db
      .insert(site)
      .values({ projectId: other.projectId, name: 'Other plot' })
      .returning();
    const [otherPeriod] = await db
      .insert(surveyPeriod)
      .values({
        projectId: other.projectId,
        name: 'Other period',
        startDate: '2024-01-01',
        endDate: '2024-02-29',
      })
      .returning();
    const [otherVisit] = await db
      .insert(visit)
      .values({
        id: '00000000-0000-0000-0000-0000000000ff',
        projectId: other.projectId,
        siteId: otherSite!.id,
        surveyPeriodId: otherPeriod!.id,
        protocolVersionId: other.protocolVersionId,
        taxonomicReferenceId: 'italy-vascular-flora',
        taxonomicReferenceVersion: '2024.1',
        state: 'submitted',
        effort: {},
        startedAt: new Date('2024-01-15T00:00:00.000Z'),
        submittedAt: new Date('2024-01-15T01:00:00.000Z'),
      })
      .returning();

    const [record] = await db
      .insert(exportRecord)
      .values({ projectId, format: 'csv' })
      .returning();

    const generator = app.get(DetectionHistoryGenerator);
    const bytes = await generator.generate(record!);
    const csv = new TextDecoder().decode(bytes);

    const expected = [
      'site_id,survey_period_id,visit_id,started_at,B,A',
      `${site1},${period1},${visit1},2024-01-01T00:00:00.000Z,1,0`,
      `${site2},${period2},${visit2},2024-02-01T00:00:00.000Z,0,1`,
    ].join('\r\n');

    expect(csv).toBe(expected);
    expect(csv).not.toContain(otherVisit!.id);
    expect(builderCalls).toHaveLength(1);
    expect(builderCalls[0]!.map((entry) => entry.visitId).sort()).toEqual([
      visit1,
      visit2,
    ]);
  });
});
