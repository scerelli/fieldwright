CREATE TABLE "protocol_version" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"protocol_id" text NOT NULL,
	"version" integer NOT NULL,
	"document" jsonb NOT NULL,
	"frozen_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "protocol_version" ADD CONSTRAINT "protocol_version_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "protocol_version_project_protocol_version_key" ON "protocol_version" USING btree ("project_id","protocol_id","version");