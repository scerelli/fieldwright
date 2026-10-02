-- The Project's optional authored description (DOMAIN.md Project aggregate,
-- ADR-0016). Added nullable so the migration applies as-is to a database that
-- already holds Projects (ARCHITECTURE.md Server-schema compatibility); the
-- description travels to a Project's members through `POST /projects` and the
-- config pull.
-- `IF NOT EXISTS` keeps the migration replay-safe, like 0013 and 0014: the
-- existing populated-database migration tests re-apply later migrations to a
-- database that already has the column.
ALTER TABLE "project" ADD COLUMN IF NOT EXISTS "description" text;