-- Baselines the database: enables PostGIS so later migrations can declare
-- geometry columns. drizzle-kit has no schema primitive for extensions, so this
-- is a custom migration generated with `drizzle-kit generate --custom`.
CREATE EXTENSION IF NOT EXISTS postgis;