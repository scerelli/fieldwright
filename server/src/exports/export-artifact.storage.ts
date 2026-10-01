/**
 * The `exports` module's artifact store (ARCHITECTURE.md, ADR-0007): the
 * server-side, content-addressed store a worker writes a generated Export
 * artifact to and the API reads it back from. It is the same media backend the
 * `media` module serves Evidence from — the system view routes the worker to
 * the media volume / S3, not a second store — but the export path writes
 * **server-side** (the worker runs on the server), whereas Evidence is written
 * by a presigned client PUT (ADR-0012).
 */
import type { ArtifactStorage } from '../media/media.storage.js';

/** DI token for the bound `ExportArtifactStorage` the `exports` module uses. */
export const EXPORT_ARTIFACT_STORAGE = 'EXPORT_ARTIFACT_STORAGE';

/**
 * A server-side artifact store: `put` writes the bytes itself and returns the
 * lowercase-hex SHA-256 key they are addressed by; a stored artifact is
 * immutable, so identical bytes dedupe and are never rewritten.
 */
export type ExportArtifactStorage = ArtifactStorage;
