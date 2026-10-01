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
  /**
   * Headers the client must send with the `uploadUrl` PUT. The URL is signed
   * with an `If-None-Match: *` precondition and an `x-amz-checksum-sha256`
   * content checksum bound to the exact bytes and length the API received, so
   * a PUT must carry these or the object store rejects it; `Content-Length` is
   * set by the HTTP client from the body. Absent for the volume backend.
   */
  uploadHeaders?: Record<string, string>;
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

/**
 * The additive server-side write capability of a storage backend. A writer
 * that runs on the server — the `exports` worker — stores the bytes itself and
 * gets their content-addressed key back, where `MediaStorage.store` instead
 * hands a client a presigned PUT on the S3 backend (ADR-0012). The stored
 * artifact is immutable once written: identical bytes resolve to the same key
 * and never rewrite it (ADR-0007).
 */
export interface ArtifactStorage {
  /** Writes bytes server-side and returns their lowercase-hex SHA-256 key. */
  put(bytes: Uint8Array): Promise<string>;
  /** Returns the stored bytes, or `null` when no artifact names that key. */
  fetch(storageKey: string): Promise<Uint8Array | null>;
}

/**
 * A storage backend: the Evidence `MediaStorage` contract plus the additive
 * server-side `ArtifactStorage` put, served by the same backend so the
 * `exports` worker writes to the same volume or S3 Store the `media` module
 * uses (ADR-0007).
 */
export interface StorageBackend extends MediaStorage, ArtifactStorage {}
