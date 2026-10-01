/**
 * The server `media` module's Evidence storage service (ARCHITECTURE.md,
 * ADR-0012): stores an uploaded Evidence file and fetches one back by its
 * content-addressed key, delegating to the backend-agnostic `MediaStorage`
 * abstraction. These endpoints write the file only; the Evidence record is
 * persisted with the submitted Visit by the `visits` module.
 */
import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  MEDIA_STORAGE,
  type MediaStorage,
  type StoredMedia,
} from './media.storage.js';

@Injectable()
export class MediaService {
  constructor(@Inject(MEDIA_STORAGE) private readonly storage: MediaStorage) {}

  /** Stores the bytes and returns their content-addressed key and SHA-256. */
  store(bytes: Uint8Array): Promise<StoredMedia> {
    return this.storage.store(bytes);
  }

  /**
   * Returns the stored bytes for a key, or raises 404 when no file names it.
   * A malformed key is not-found too, so an untrusted path is never a lookup.
   */
  async fetch(storageKey: string): Promise<Uint8Array> {
    const bytes = await this.storage.fetch(storageKey);
    if (bytes === null) {
      throw new NotFoundException();
    }
    return bytes;
  }
}
