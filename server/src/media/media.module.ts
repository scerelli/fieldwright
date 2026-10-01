/**
 * The served application's `media` module (ARCHITECTURE.md): binds the
 * `MediaStorage` abstraction to the backend selected by the environment and
 * exposes the auth-guarded Evidence upload/download surface, so a consumer
 * stores and fetches Evidence without knowing whether it lands on the volume
 * or (later) an S3 backend.
 */
import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DatabaseModule } from '../db/database.module.js';
import {
  loadMediaConfig,
  MEDIA_CONFIG,
  type MediaConfig,
} from './media.config.js';
import { MediaController } from './media.controller.js';
import { MediaService } from './media.service.js';
import { MEDIA_STORAGE } from './media.storage.js';
import { createVolumeStorage } from './volume.storage.js';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [MediaController],
  providers: [
    { provide: MEDIA_CONFIG, useFactory: () => loadMediaConfig() },
    {
      provide: MEDIA_STORAGE,
      useFactory: (config: MediaConfig) => createVolumeStorage(config.root),
      inject: [MEDIA_CONFIG],
    },
    MediaService,
  ],
  exports: [MEDIA_STORAGE, MediaService],
})
export class MediaModule {}
