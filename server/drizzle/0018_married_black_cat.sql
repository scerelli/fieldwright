-- The Visit's pinned Taxonomic reference id and version are a pair, recorded
-- together or not at all (DOMAIN.md, INV-021): a Visit that stores exactly one
-- of the two is rejected, so a resolved Detection always carries the reference
-- version it resolved against. Forward-only and replay-safe like 0013–0017
-- (ARCHITECTURE.md Server-schema compatibility): the pre-emptive
-- `DROP CONSTRAINT IF EXISTS` lets the populated-database migration tests
-- re-apply this file to a database that already has the constraint.
ALTER TABLE "visit" DROP CONSTRAINT IF EXISTS "visit_reference_pair";--> statement-breakpoint
ALTER TABLE "visit" ADD CONSTRAINT "visit_reference_pair" CHECK (("visit"."taxonomic_reference_id" is null) = ("visit"."taxonomic_reference_version" is null));