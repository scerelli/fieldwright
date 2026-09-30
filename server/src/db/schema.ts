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
 * role they hold there. `person_id` references the Better Auth `user` table.
 */
export const membership = pgTable('membership', {
  id: uuid('id').primaryKey().defaultRandom(),
  personId: text('person_id')
    .notNull()
    .references(() => user.id, { onDelete: 'cascade' }),
  projectId: uuid('project_id')
    .notNull()
    .references(() => project.id, { onDelete: 'cascade' }),
  role: membershipRole('role').notNull(),
});

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
