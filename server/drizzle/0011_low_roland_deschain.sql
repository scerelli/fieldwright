-- Record the Project's pinned Taxonomic reference id and version on the Visit
-- (INV-008). Forward-only: the columns are added nullable, existing Visit rows
-- are backfilled from their owning Project's pin, then the columns are made NOT
-- NULL — so the migration succeeds on a database that already holds Visits,
-- not only on an empty one (ARCHITECTURE.md Server-schema compatibility).
-- The backfill is a schema evolution by the migration owner, not an
-- application edit, so it disables the INV-001 immutability trigger for the
-- duration of the UPDATE and re-enables it immediately after.
ALTER TABLE "visit" ADD COLUMN "taxonomic_reference_id" text;--> statement-breakpoint
ALTER TABLE "visit" ADD COLUMN "taxonomic_reference_version" text;--> statement-breakpoint
ALTER TABLE "visit" DISABLE TRIGGER "visit_immutable";--> statement-breakpoint
UPDATE "visit" SET "taxonomic_reference_id" = "project"."taxonomic_reference_id", "taxonomic_reference_version" = "project"."taxonomic_reference_version" FROM "project" WHERE "visit"."project_id" = "project"."id";--> statement-breakpoint
ALTER TABLE "visit" ENABLE TRIGGER "visit_immutable";--> statement-breakpoint
ALTER TABLE "visit" ALTER COLUMN "taxonomic_reference_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "visit" ALTER COLUMN "taxonomic_reference_version" SET NOT NULL;
