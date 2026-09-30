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
import {
  boolean,
  pgEnum,
  pgTable,
  text,
  timestamp,
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

export const membershipRole = pgEnum('membership_role', [
  'creator',
  'collector',
  'validator',
]);

/**
 * Membership (DOMAIN.md): the link between a person and a Project carrying the
 * role they hold there. `person_id` references the Better Auth `user` table.
 * The `project` table does not exist yet, so `project_id` is a plain uuid
 * without a foreign key; add the reference when Project lands.
 */
export const membership = pgTable('membership', {
  id: uuid('id').primaryKey().defaultRandom(),
  personId: text('person_id')
    .notNull()
    .references(() => user.id, { onDelete: 'cascade' }),
  projectId: uuid('project_id').notNull(),
  role: membershipRole('role').notNull(),
});

export type Membership = typeof membership.$inferSelect;
