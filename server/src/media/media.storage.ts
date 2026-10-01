/**
 * The `media` module's storage abstraction (ARCHITECTURE.md): a
 * backend-agnostic way to store and fetch an Evidence file. A stored file is
 * addressed by the lowercase-hex SHA-256 of its bytes, so re-storing identical
 * bytes resolves to the same key and never mutates the stored file (ADR-0007,
 * ADR-0012).
 */

/** DI token for the bound `MediaStorage` implementation. */
export const MEDIA_STORAGE = 'MEDIA_STORAGE';

/** An Evidence file's content-addressed key, and the SHA-256 it is keyed by. */
export interface StoredMedia {
  storageKey: string;
  sha256: string;
  /**
   * A presigned S3 URL the client PUTs the bytes to, when an S3 backend is
   * configured and the object is not stored yet. Absent for the volume
   * backend (bytes are stored here) and for an S3 object already present, so
   * an existing Evidence file is never overwritten (ADR-0012).
   */
  uploadUrl?: string;
}

export interface MediaStorage {
  /** Stores bytes and returns their content-addressed key and SHA-256. */
  store(bytes: Uint8Array): Promise<StoredMedia>;
  /**
   * Returns the stored bytes, or `null` when no file names that key. A key
   * that is not a content hash — the untrusted input a download endpoint
   * carries — is not-found rather than a lookup path.
   */
  fetch(storageKey: string): Promise<Uint8Array | null>;
}
