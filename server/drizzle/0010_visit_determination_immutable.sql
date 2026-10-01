-- The database safety net for submitted-record immutability (ADR-0010,
-- INV-001, INV-009). A stored Visit is never edited or deleted — every later
-- change is a Correction; a stored Determination is append-only, so a revision
-- is a new row linking to the one it replaces, never an overwrite.
CREATE OR REPLACE FUNCTION reject_stored_visit_mutation() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.state IN ('submitted', 'validated', 'rejected') THEN
    RAISE EXCEPTION 'a stored Visit is immutable (INV-001): cannot % visit %', lower(TG_OP), OLD.id
      USING ERRCODE = 'restrict_violation';
  END IF;
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;
--> statement-breakpoint
CREATE TRIGGER visit_immutable
  BEFORE UPDATE OR DELETE ON "visit"
  FOR EACH ROW
  EXECUTE FUNCTION reject_stored_visit_mutation();
--> statement-breakpoint
CREATE OR REPLACE FUNCTION reject_determination_update() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'a stored Determination is never overwritten (INV-009)'
    USING ERRCODE = 'restrict_violation';
END;
$$;
--> statement-breakpoint
CREATE TRIGGER determination_immutable
  BEFORE UPDATE ON "determination"
  FOR EACH ROW
  EXECUTE FUNCTION reject_determination_update();
