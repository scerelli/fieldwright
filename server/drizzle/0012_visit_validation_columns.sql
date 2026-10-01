-- The Visit's Validation columns and the relaxed database safety net for the
-- Validation transition (ADR-0010, INV-001, INV-013). `validator_id` references
-- the Person who holds the `validator` Membership and `validated_at` is the
-- Validation instant; both are added nullable so the migration applies as-is on
-- a database that already holds a submitted Visit (ARCHITECTURE.md Server-schema
-- compatibility).
--
-- Replaces the `reject_stored_visit_mutation` function created by
-- 0010_visit_determination_immutable.sql. The `visit_immutable` trigger keeps
-- pointing at it, so only the body changes: a stored Visit is still never
-- deleted, and is still never edited — except for one permitted change, a
-- `submitted` Visit becoming `validated` or `rejected` while recording the
-- validator and the time (INV-013).
ALTER TABLE "visit" ADD COLUMN "validator_id" text;--> statement-breakpoint
ALTER TABLE "visit" ADD COLUMN "validated_at" timestamp;--> statement-breakpoint
ALTER TABLE "visit" ADD CONSTRAINT "visit_validator_id_user_id_fk" FOREIGN KEY ("validator_id") REFERENCES "public"."user"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
CREATE OR REPLACE FUNCTION reject_stored_visit_mutation() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.state IN ('submitted', 'validated', 'rejected') THEN
      RAISE EXCEPTION 'a stored Visit is never deleted (INV-001, INV-013): cannot delete visit %', OLD.id
        USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN OLD;
  END IF;

  IF OLD.state IN ('validated', 'rejected') THEN
    RAISE EXCEPTION 'a stored Visit is immutable (INV-001, INV-013): cannot update a % visit %', OLD.state, OLD.id
      USING ERRCODE = 'restrict_violation';
  END IF;

  IF OLD.state = 'submitted' THEN
    IF NEW.state NOT IN ('validated', 'rejected') THEN
      RAISE EXCEPTION 'a Validation moves a submitted Visit only to validated or rejected (INV-013): cannot set visit % to %', OLD.id, NEW.state
        USING ERRCODE = 'restrict_violation';
    END IF;
    IF NEW.validator_id IS NULL OR NEW.validated_at IS NULL THEN
      RAISE EXCEPTION 'a Validation records the validator and the time (INV-013): visit %', OLD.id
        USING ERRCODE = 'restrict_violation';
    END IF;
    IF (to_jsonb(NEW) - 'state' - 'validator_id' - 'validated_at')
         IS DISTINCT FROM
       (to_jsonb(OLD) - 'state' - 'validator_id' - 'validated_at') THEN
      RAISE EXCEPTION 'a Validation changes only state, validator and time (INV-001): cannot edit visit %', OLD.id
        USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;
