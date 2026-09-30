CREATE TABLE "survey_period" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"name" text NOT NULL,
	"start_date" date NOT NULL,
	"end_date" date NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "survey_period_date_range" CHECK ("survey_period"."end_date" >= "survey_period"."start_date")
);
--> statement-breakpoint
ALTER TABLE "survey_period" ADD CONSTRAINT "survey_period_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;