CREATE TYPE "public"."determination_qualifier" AS ENUM('cf.', 'aff.', 'sp.');--> statement-breakpoint
CREATE TABLE "determination" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"detection_id" uuid NOT NULL,
	"taxon" text NOT NULL,
	"qualifier" "determination_qualifier",
	"specimen_code" text,
	"determiner" text NOT NULL,
	"date" date NOT NULL,
	"replaces_id" uuid
);
--> statement-breakpoint
ALTER TABLE "determination" ADD CONSTRAINT "determination_detection_id_detection_id_fk" FOREIGN KEY ("detection_id") REFERENCES "public"."detection"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "determination" ADD CONSTRAINT "determination_replaces_id_determination_id_fk" FOREIGN KEY ("replaces_id") REFERENCES "public"."determination"("id") ON DELETE set null ON UPDATE no action;