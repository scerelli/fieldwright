-- The durable Export record (ARCHITECTURE.md `exports` module): one requested
-- export of a Project's data, carrying the requested format, its lifecycle
-- state, the artifact's storage key once produced, and the failure reason when
-- its job fails. Forward-only and replay-safe: like 0013's CREATE OR REPLACE
-- trigger, it is idempotent, so the migration test can re-apply it to a
-- database that already has it (ARCHITECTURE.md Server-schema compatibility).
-- The enum is created unless it exists, the table unless it exists, and the
-- Project foreign key is dropped before it is re-added.
DO $$ BEGIN
	CREATE TYPE "public"."export_state" AS ENUM('requested', 'processing', 'succeeded', 'failed');
EXCEPTION
	WHEN duplicate_object THEN NULL;
END $$;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "export" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"format" text NOT NULL,
	"state" "export_state" DEFAULT 'requested' NOT NULL,
	"storage_key" text,
	"error" text,
	"created_at" timestamp DEFAULT now() NOT NULL
);--> statement-breakpoint
ALTER TABLE "export" DROP CONSTRAINT IF EXISTS "export_project_id_project_id_fk";--> statement-breakpoint
ALTER TABLE "export" ADD CONSTRAINT "export_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;
