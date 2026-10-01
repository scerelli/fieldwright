-- The database safety net for Correction append-only-ness (ADR-0010, INV-001,
-- INV-013). A Correction is the only way a stored Visit changes in effect, and
-- it is itself never changed or removed: the `correction_immutable` trigger
-- rejects any UPDATE or DELETE of a `correction` row, so a later change is a
-- new Correction, never an overwrite. Mirrors `determination_immutable` from
-- 0010_visit_determination_immutable.sql.
CREATE OR REPLACE FUNCTION reject_correction_mutation() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'a stored Correction is append-only (INV-001, INV-013): cannot % correction %', lower(TG_OP), OLD.id
    USING ERRCODE = 'restrict_violation';
END;
$$;
--> statement-breakpoint
-- CREATE OR REPLACE (not plain CREATE) so the migration is idempotent: the
-- migration test re-applies every migration after 0010 to a database that
-- already has them, exactly as 0012's CREATE OR REPLACE FUNCTION survives.
CREATE OR REPLACE TRIGGER correction_immutable
  BEFORE UPDATE OR DELETE ON "correction"
  FOR EACH ROW
  EXECUTE FUNCTION reject_correction_mutation();
