-- The Project's pinned Taxonomic reference id and version become nullable
-- (DOMAIN.md Project aggregate): a creator may start a Project before choosing
-- a reference, so the columns accept NULL until one is pinned. Forward-only and
-- replay-safe (ARCHITECTURE.md Server-schema compatibility): dropping NOT NULL
-- is idempotent, so the populated-database migration test can re-apply this file
-- to a database that already has the change.
ALTER TABLE "project" ALTER COLUMN "taxonomic_reference_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "project" ALTER COLUMN "taxonomic_reference_version" DROP NOT NULL;
