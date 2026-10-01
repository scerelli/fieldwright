/**
 * RFC 4180 CSV serialization for the `exports` module (ARCHITECTURE.md). The
 * writer is hand-written and dependency-free: fields are joined with `,` and
 * records with CRLF, and a field containing a comma, a double quote or a line
 * break is quoted with each embedded double quote doubled. Identical input
 * rows always produce identical text, so an Export artifact is reproducible.
 */

/** The characters that force a CSV field to be quoted (RFC 4180). */
const MUST_QUOTE = /[",\r\n]/;

/**
 * Quotes one CSV field (RFC 4180) when it contains a comma, a double quote or
 * a line break; every embedded double quote is doubled. Returns the field
 * unchanged otherwise.
 */
export function escapeCsvField(field: string): string {
  if (MUST_QUOTE.test(field)) {
    return `"${field.replace(/"/g, '""')}"`;
  }
  return field;
}

/**
 * Serializes `rows` to RFC 4180 CSV text: each row's fields joined with `,`
 * and each record terminated by CRLF, quoting fields as {@link escapeCsvField}
 * requires. No trailing CRLF follows the last record.
 */
export function serializeCsv(rows: readonly (readonly string[])[]): string {
  return rows
    .map((row) => row.map((field) => escapeCsvField(field)).join(','))
    .join('\r\n');
}
