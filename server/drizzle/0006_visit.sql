CREATE TYPE "public"."evidence_kind" AS ENUM('photo', 'audio');--> statement-breakpoint
CREATE TYPE "public"."visit_state" AS ENUM('in_progress', 'ended', 'submitted', 'validated', 'rejected');--> statement-breakpoint
CREATE TABLE "correction" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"visit_id" uuid NOT NULL,
	"author_id" text NOT NULL,
	"reason" text NOT NULL,
	"payload" jsonb NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "detection" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"visit_id" uuid NOT NULL,
	"taxon" text NOT NULL,
	"detected" boolean NOT NULL,
	"method" text NOT NULL,
	"count" integer,
	"opportunistic" boolean DEFAULT false NOT NULL,
	CONSTRAINT "detection_count_non_negative" CHECK ("detection"."count" is null or "detection"."count" >= 0)
);
--> statement-breakpoint
CREATE TABLE "evidence" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"visit_id" uuid NOT NULL,
	"detection_id" uuid,
	"kind" "evidence_kind" NOT NULL,
	"storage_key" text NOT NULL,
	"sha256" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "measurement" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"visit_id" uuid NOT NULL,
	"detection_id" uuid,
	"value" text NOT NULL,
	"unit" text NOT NULL,
	"provenance" jsonb NOT NULL,
	CONSTRAINT "measurement_provenance_method" CHECK ("measurement"."provenance"->>'method' is not null)
);
--> statement-breakpoint
CREATE TABLE "site" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"name" text,
	"geom" text,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "visit" (
	"id" uuid PRIMARY KEY NOT NULL,
	"project_id" uuid NOT NULL,
	"site_id" uuid NOT NULL,
	"survey_period_id" uuid NOT NULL,
	"protocol_version_id" uuid NOT NULL,
	"state" "visit_state" NOT NULL,
	"effort" jsonb NOT NULL,
	"started_at" timestamp NOT NULL,
	"ended_at" timestamp,
	"submitted_at" timestamp NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "correction" ADD CONSTRAINT "correction_visit_id_visit_id_fk" FOREIGN KEY ("visit_id") REFERENCES "public"."visit"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "correction" ADD CONSTRAINT "correction_author_id_user_id_fk" FOREIGN KEY ("author_id") REFERENCES "public"."user"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "detection" ADD CONSTRAINT "detection_visit_id_visit_id_fk" FOREIGN KEY ("visit_id") REFERENCES "public"."visit"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "evidence" ADD CONSTRAINT "evidence_visit_id_visit_id_fk" FOREIGN KEY ("visit_id") REFERENCES "public"."visit"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "evidence" ADD CONSTRAINT "evidence_detection_id_detection_id_fk" FOREIGN KEY ("detection_id") REFERENCES "public"."detection"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "measurement" ADD CONSTRAINT "measurement_visit_id_visit_id_fk" FOREIGN KEY ("visit_id") REFERENCES "public"."visit"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "measurement" ADD CONSTRAINT "measurement_detection_id_detection_id_fk" FOREIGN KEY ("detection_id") REFERENCES "public"."detection"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "site" ADD CONSTRAINT "site_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "visit" ADD CONSTRAINT "visit_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "visit" ADD CONSTRAINT "visit_site_id_site_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."site"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "visit" ADD CONSTRAINT "visit_survey_period_id_survey_period_id_fk" FOREIGN KEY ("survey_period_id") REFERENCES "public"."survey_period"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "visit" ADD CONSTRAINT "visit_protocol_version_id_protocol_version_id_fk" FOREIGN KEY ("protocol_version_id") REFERENCES "public"."protocol_version"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "detection_visit_taxon_target_key" ON "detection" USING btree ("visit_id","taxon") WHERE not "detection"."opportunistic";