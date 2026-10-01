/**
 * Protocol-level submission rules for the `visits` module (DOMAIN.md,
 * ARCHITECTURE.md). A rule is a pure predicate over a submission's data and
 * the Protocol version document it references; the ingest transaction in
 * `visits.service.ts` loads that document and runs these before storing, so a
 * rejected submission leaves no Visit behind (ADR-0010: rule-heavy rules run
 * in server code inside a transaction).
 */
import { BadRequestException } from '@nestjs/common';

/**
 * The Sampling-effort field names a Protocol version's document requires, read
 * from its `requiredEffortFields` (packages/protocol `SamplingEffortField`). A
 * document that omits the list requires no Sampling-effort field.
 */
export function requiredEffortFieldsOf(
  document: Record<string, unknown>,
): string[] {
  const value = document.requiredEffortFields;
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((entry): entry is string => typeof entry === 'string');
}

/** The required Sampling-effort fields `effort` does not record a value for. */
export function missingRequiredEffortFields(
  effort: Record<string, unknown>,
  requiredEffortFields: readonly string[],
): string[] {
  return requiredEffortFields.filter((field) => {
    const value = effort[field];
    return value === undefined || value === null;
  });
}

/**
 * Rejects a submission whose Sampling effort omits a field its Protocol
 * version requires (INV-005). Runs inside the ingest transaction, so throwing
 * here stores no Visit.
 */
export function assertRequiredEffortFields(
  effort: Record<string, unknown>,
  requiredEffortFields: readonly string[],
): void {
  const missing = missingRequiredEffortFields(effort, requiredEffortFields);
  if (missing.length > 0) {
    throw new BadRequestException(
      `Sampling effort is missing required field(s): ${missing.join(', ')}`,
    );
  }
}
