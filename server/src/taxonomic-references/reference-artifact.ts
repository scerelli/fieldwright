/**
 * The Taxonomic-reference artifact format (ARCHITECTURE.md, ADR-0020): the
 * immutable, versioned JSON an operator places on the reference volume and the
 * API serves by `id` + `version`. It carries the reference's identity and label
 * plus the taxa the client resolves names against — the same shape the client's
 * `taxonomic_references` cache holds.
 *
 * The format is additive: only the fields below are part of it, so a file that
 * carries extra fields is read with those fields ignored rather than served
 * verbatim.
 */

/** One taxon of a reference: the abbreviation a Detection records and its name. */
export interface ReferenceTaxon {
  abbreviation: string;
  name: string;
}

/** A versioned Taxonomic-reference artifact, served immutably by `id`+`version`. */
export interface ReferenceArtifact {
  id: string;
  version: string;
  label: string;
  taxonGroup: string;
  taxa: ReferenceTaxon[];
}

/**
 * Reads one artifact from untrusted parsed JSON, projecting it onto the format
 * above. Unknown fields are ignored; a value missing a required field, or a
 * `taxa` entry that is not a `{ abbreviation, name }` pair, is not an artifact
 * and yields `null`.
 */
export function parseReferenceArtifact(raw: unknown): ReferenceArtifact | null {
  if (!isRecord(raw)) {
    return null;
  }

  const id = stringField(raw, 'id');
  const version = stringField(raw, 'version');
  const label = stringField(raw, 'label');
  const taxonGroup = stringField(raw, 'taxonGroup');
  const taxa = parseTaxa(raw.taxa);
  if (
    id === null ||
    version === null ||
    label === null ||
    taxonGroup === null ||
    taxa === null
  ) {
    return null;
  }

  return { id, version, label, taxonGroup, taxa };
}

function parseTaxa(raw: unknown): ReferenceTaxon[] | null {
  if (!Array.isArray(raw)) {
    return null;
  }

  const taxa: ReferenceTaxon[] = [];
  for (const entry of raw) {
    if (!isRecord(entry)) {
      return null;
    }
    const abbreviation = stringField(entry, 'abbreviation');
    const name = stringField(entry, 'name');
    if (abbreviation === null || name === null) {
      return null;
    }
    taxa.push({ abbreviation, name });
  }
  return taxa;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function stringField(
  record: Record<string, unknown>,
  key: string,
): string | null {
  const value = record[key];
  return typeof value === 'string' && value.length > 0 ? value : null;
}
