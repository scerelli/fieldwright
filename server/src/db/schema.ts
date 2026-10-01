/**
 * Drizzle schema entry point, read by `drizzle.config.ts`.
 *
 * Domain tables are declared here (or re-exported from modules beside it) as
 * the data model grows. The PostGIS extension is enabled by the baseline custom
 * migration (`drizzle/0000_baseline.sql`), because drizzle-kit has no schema
 * primitive for creating extensions.
 *
 * The `user`, `session`, `account` and `verification` tables are owned by  // glossary:allow Better Auth's auth tables, not domain aggregates
 * Better Auth (ADR-0003) and co-located here so a single drizzle-kit migration
 * creates them alongside the domain tables. Their JavaScript keys must match
 * Better Auth's field names; the snake_case column names are the store's.
 */
import { sql } from 'drizzle-orm';
import {
  type AnyPgColumn,
  boolean,
  check,
  date,
  integer,
  jsonb,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';

export const user = pgTable('user', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  emailVerified: boolean('email_verified').default(false).notNull(),
  image: text('image'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

const authState = pgTable(
  /* glossary:allow Better Auth's auth-session table, not the Visit */ 'session',
  {
    id: text('id').primaryKey(),
    expiresAt: timestamp('expires_at').notNull(),
    token: text('token').notNull().unique(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
    ipAddress: text('ip_address'),
    userAgent: text('user_agent'),
    userId: text('user_id')
      .notNull()
      .references(() => user.id, { onDelete: 'cascade' }),
  },
);

export { authState as session }; // glossary:allow Better Auth's auth-session table, not the Visit

export const account = pgTable('account', {
  id: text('id').primaryKey(),
  accountId: text('account_id').notNull(),
  providerId: text('provider_id').notNull(),
  userId: text('user_id')
    .notNull()
    .references(() => user.id, { onDelete: 'cascade' }),
  accessToken: text('access_token'),
  refreshToken: text('refresh_token'),
  idToken: text('id_token'),
  accessTokenExpiresAt: timestamp('access_token_expires_at'),
  refreshTokenExpiresAt: timestamp('refresh_token_expires_at'),
  scope: text('scope'),
  password: text('password'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const verification = pgTable('verification', {
  id: text('id').primaryKey(),
  identifier: text('identifier').notNull(),
  value: text('value').notNull(),
  expiresAt: timestamp('expires_at').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

/**
 * Project settings (DOMAIN.md): validation on/off and sensitive-taxa
 * coordinate obfuscation. The pinned Taxonomic reference version is recorded
 * in its own columns below.
 */
export interface ProjectSettings {
  validationEnabled: boolean;
  sensitiveTaxaObfuscation: boolean;
}

/**
 * Project (DOMAIN.md): the container a creator sets up. Its Memberships,
 * Protocol versions, Survey periods and Sites are scoped to it.
 */
export const project = pgTable('project', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull(),
  settings: jsonb('settings').$type<ProjectSettings>().notNull(),
  taxonomicReferenceId: text('taxonomic_reference_id').notNull(),
  taxonomicReferenceVersion: text('taxonomic_reference_version').notNull(),
});

export type Project = typeof project.$inferSelect;

export const membershipRole = pgEnum('membership_role', [
  'creator',
  'collector',
  'validator',
]);

/**
 * Membership (DOMAIN.md): the link between a person and a Project carrying the
 * role they hold there. `person_id` references the Better Auth `user` table. A
 * person has at most one Membership per Project (INV-014), enforced by the
 * unique index on `(person_id, project_id)`.
 */
export const membership = pgTable(
  'membership',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    personId: text('person_id')
      .notNull()
      .references(() => user.id, { onDelete: 'cascade' }),
    projectId: uuid('project_id')
      .notNull()
      .references(() => project.id, { onDelete: 'cascade' }),
    role: membershipRole('role').notNull(),
  },
  (table) => [
    uniqueIndex('membership_person_project_key').on(
      table.personId,
      table.projectId,
    ),
  ],
);

export type Membership = typeof membership.$inferSelect;

/**
 * Protocol version (DOMAIN.md): an immutable snapshot of a Protocol, an entity
 * inside Project. `document` is the versioned protocol document, validated
 * against the packages/protocol JSON Schema; the monotonic `version` is
 * server-assigned per Protocol identity. `frozen_at` is set the first time a
 * Visit references the version (INV-007): a frozen version is never updated,
 * and a change creates a new version.
 */
export const protocolVersion = pgTable(
  'protocol_version',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    projectId: uuid('project_id')
      .notNull()
      .references(() => project.id, { onDelete: 'cascade' }),
    protocolId: text('protocol_id').notNull(),
    version: integer('version').notNull(),
    document: jsonb('document').$type<Record<string, unknown>>().notNull(),
    frozenAt: timestamp('frozen_at'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    uniqueIndex('protocol_version_project_protocol_version_key').on(
      table.projectId,
      table.protocolId,
      table.version,
    ),
  ],
);

export type ProtocolVersion = typeof protocolVersion.$inferSelect;

/**
 * Survey period (DOMAIN.md): a project-scoped entity inside Project, a named
 * date range in which Visits are expected. A Survey period belongs to exactly
 * one Project, and its end date never precedes its start date (enforced here
 * as a Check and mirrored in the service).
 */
export const surveyPeriod = pgTable(
  'survey_period',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    projectId: uuid('project_id')
      .notNull()
      .references(() => project.id, { onDelete: 'cascade' }),
    name: text('name').notNull(),
    startDate: date('start_date').notNull(),
    endDate: date('end_date').notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    check(
      'survey_period_date_range',
      sql`${table.endDate} >= ${table.startDate}`,
    ),
  ],
);

export type SurveyPeriod = typeof surveyPeriod.$inferSelect;

/**
 * Site (DOMAIN.md): a place a survey happens, scoped to exactly one Project
 * (INV-012). Epic #4 built the client surface, so this is the minimal server
 * row the Visit's Site foreign key needs: an identity, its Project, an optional
 * name and its geometry as GeoJSON text. The full Site lifecycle and origin
 * are added by the server `sites` module.
 */
export const site = pgTable('site', {
  id: uuid('id').primaryKey().defaultRandom(),
  projectId: uuid('project_id')
    .notNull()
    .references(() => project.id, { onDelete: 'cascade' }),
  name: text('name'),
  geom: text('geom'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export type Site = typeof site.$inferSelect;

/**
 * Visit lifecycle (DOMAIN.md): in progress on the device, ended by the
 * collector, submitted immutably, then validated or rejected when the Project
 * has validation enabled.
 */
export const visitState = pgEnum('visit_state', [
  'in_progress',
  'ended',
  'submitted',
  'validated',
  'rejected',
]);

/**
 * Visit (DOMAIN.md): the unit of offline capture, submission and immutability.
 * Its id is a client-generated UUIDv7. It references exactly one Site, one
 * Survey period and one Protocol version (INV-006), enforced by the non-null
 * foreign keys below; `ended_at` and `submitted_at` never precede `started_at`
 * (check `visit_timestamps_ordered`). `effort` holds the Sampling effort fields
 * the Protocol version requires; `submitted_at` is the submission instant. A
 * stored Visit is immutable (INV-001): the `visit_immutable` trigger in the
 * migration permits exactly one UPDATE of a `submitted` row — the Validation
 * transition to `validated` or `rejected` (INV-013) — recording `validator_id`
 * and `validated_at` and touching no other column; every other UPDATE, and any
 * DELETE, of a stored row is rejected. A later change is a Correction.
 *
 * `validator_id` references the Better Auth `user` (the Person who holds the
 * `validator` Membership) and `validated_at` is the Validation instant; both
 * are null until the Visit is validated or rejected.
 *
 * `taxonomic_reference_id` and `taxonomic_reference_version` record the
 * Project's pinned Taxonomic reference version the Visit's data was captured
 * against (INV-008); the ingest transaction copies the pin from the Project,
 * and the NOT NULL columns reject a Visit row stored without one.
 */
export const visit = pgTable(
  'visit',
  {
    id: uuid('id').primaryKey(),
    projectId: uuid('project_id')
      .notNull()
      .references(() => project.id, { onDelete: 'cascade' }),
    siteId: uuid('site_id')
      .notNull()
      .references(() => site.id, { onDelete: 'cascade' }),
    surveyPeriodId: uuid('survey_period_id')
      .notNull()
      .references(() => surveyPeriod.id, { onDelete: 'cascade' }),
    protocolVersionId: uuid('protocol_version_id')
      .notNull()
      .references(() => protocolVersion.id, { onDelete: 'cascade' }),
    taxonomicReferenceId: text('taxonomic_reference_id').notNull(),
    taxonomicReferenceVersion: text('taxonomic_reference_version').notNull(),
    state: visitState('state').notNull(),
    effort: jsonb('effort').$type<Record<string, unknown>>().notNull(),
    startedAt: timestamp('started_at').notNull(),
    endedAt: timestamp('ended_at'),
    submittedAt: timestamp('submitted_at').notNull(),
    validatorId: text('validator_id').references(() => user.id, {
      onDelete: 'restrict',
    }),
    validatedAt: timestamp('validated_at'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    check(
      'visit_timestamps_ordered',
      sql`(${table.endedAt} is null or ${table.endedAt} >= ${table.startedAt}) and ${table.submittedAt} >= ${table.startedAt}`,
    ),
  ],
);

export type Visit = typeof visit.$inferSelect;

/**
 * Detection (DOMAIN.md): one taxon detected, or searched for and not detected,
 * in one Visit. A non-detection is a Detection with `detected = false`. A
 * target-taxon Detection is unique per Visit; opportunistic Detections are
 * not, and never imply a non-detection (INV-003). Counts are never negative.
 */
export const detection = pgTable(
  'detection',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    visitId: uuid('visit_id')
      .notNull()
      .references(() => visit.id, { onDelete: 'cascade' }),
    taxon: text('taxon').notNull(),
    detected: boolean('detected').notNull(),
    method: text('method').notNull(),
    count: integer('count'),
    opportunistic: boolean('opportunistic').default(false).notNull(),
  },
  (table) => [
    check(
      'detection_count_non_negative',
      sql`${table.count} is null or ${table.count} >= 0`,
    ),
    uniqueIndex('detection_visit_taxon_target_key')
      .on(table.visitId, table.taxon)
      .where(sql`not ${table.opportunistic}`),
  ],
);

export type Detection = typeof detection.$inferSelect;

/**
 * Determination qualifier (DOMAIN.md): the uncertainty qualifier a
 * Determination may carry (`cf.`, `aff.`, `sp.`).
 */
export const determinationQualifier = pgEnum('determination_qualifier', [
  'cf.',
  'aff.',
  'sp.',
]);

/**
 * Determination (DOMAIN.md): a taxon assignment for a Detection, carrying its
 * qualifier, specimen code, determiner and date. Append-only (INV-009): a
 * revision is a new row whose `replaces_id` links to the one it replaces;
 * there is no update path, so nothing is overwritten. The
 * `determination_immutable` trigger in the migration rejects any UPDATE.
 */
export const determination = pgTable('determination', {
  id: uuid('id').primaryKey().defaultRandom(),
  detectionId: uuid('detection_id')
    .notNull()
    .references(() => detection.id, { onDelete: 'cascade' }),
  taxon: text('taxon').notNull(),
  qualifier: determinationQualifier('qualifier'),
  specimenCode: text('specimen_code'),
  determiner: text('determiner').notNull(),
  date: date('date').notNull(),
  replacesId: uuid('replaces_id').references(
    (): AnyPgColumn => determination.id,
    { onDelete: 'set null' },
  ),
});

export type Determination = typeof determination.$inferSelect;

/**
 * Measurement provenance (DOMAIN.md): how a Measurement was obtained. A
 * Measurement whose Provenance has no method — absent, null or blank — is
 * invalid (INV-010), enforced by the check on the `measurement` table.
 */
export interface MeasurementProvenance {
  method: string;
  [key: string]: unknown;
}

/**
 * Measurement (DOMAIN.md): a value with a unit and its Provenance. It is owned
 * by the Visit or by one of its Detections, so `detection_id` is null for a
 * visit-level Measurement and set for a detection-level one.
 */
export const measurement = pgTable(
  'measurement',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    visitId: uuid('visit_id')
      .notNull()
      .references(() => visit.id, { onDelete: 'cascade' }),
    detectionId: uuid('detection_id').references(() => detection.id, {
      onDelete: 'cascade',
    }),
    value: text('value').notNull(),
    unit: text('unit').notNull(),
    provenance: jsonb('provenance').$type<MeasurementProvenance>().notNull(),
  },
  (table) => [
    check(
      'measurement_provenance_method',
      sql`nullif(btrim(${table.provenance}->>'method'), '') is not null`,
    ),
  ],
);

export type Measurement = typeof measurement.$inferSelect;

/**
 * Evidence (DOMAIN.md): a photo or audio recording attached to a Visit as proof
 * of a Detection. Immutable once attached: the store has no update path.
 */
export const evidenceKind = pgEnum('evidence_kind', ['photo', 'audio']);

export const evidence = pgTable('evidence', {
  id: uuid('id').primaryKey().defaultRandom(),
  visitId: uuid('visit_id')
    .notNull()
    .references(() => visit.id, { onDelete: 'cascade' }),
  detectionId: uuid('detection_id').references(() => detection.id, {
    onDelete: 'cascade',
  }),
  kind: evidenceKind('kind').notNull(),
  storageKey: text('storage_key').notNull(),
  sha256: text('sha256').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export type Evidence = typeof evidence.$inferSelect;

/**
 * Correction (DOMAIN.md): an append-only change to a submitted Visit carrying
 * its author, time, reason and payload. It never mutates the submitted Visit
 * (INV-001, INV-013); `author_id` references the Better Auth `user`. The
 * `correction_immutable` trigger in the migration rejects any UPDATE or DELETE
 * of a stored row, so a Correction is itself never changed or removed.
 */
export const correction = pgTable('correction', {
  id: uuid('id').primaryKey().defaultRandom(),
  visitId: uuid('visit_id')
    .notNull()
    .references(() => visit.id, { onDelete: 'cascade' }),
  authorId: text('author_id')
    .notNull()
    .references(() => user.id, { onDelete: 'restrict' }),
  reason: text('reason').notNull(),
  payload: jsonb('payload').$type<Record<string, unknown>>().notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export type Correction = typeof correction.$inferSelect;
