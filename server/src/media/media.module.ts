/**
 * The served application's `media` module (ARCHITECTURE.md): binds the
 * `MediaStorage` abstraction to the backend selected by the environment, so a
 * consumer stores and fetches Evidence without knowing whether it lands on the
 * volume or (later) an S3 backend.
 */
import { Module } from '@nestjs/common';
import { loadMediaConfig } from './media.config.js';
import { MEDIA_STORAGE } from './media.storage.js';
import { createVolumeStorage } from './volume.storage.js';

@Module({
  providers: [
    {
      provide: MEDIA_STORAGE,
      useFactory: () => createVolumeStorage(loadMediaConfig().root),
    },
  ],
  exports: [MEDIA_STORAGE],
})
export class MediaModule {}
