/**
 * The server `exports` module (ARCHITECTURE.md): the durable Export records and,
 * in later sub-tasks, the request/serve API, the BullMQ queue and the artifact
 * storage and generators. For now it scaffolds the module around its
 * persistence, binding `EXPORT_ARTIFACT_STORAGE` to the media backend the
 * `media` module serves from so a worker writes an Export artifact to the same
 * content-addressed volume or S3 Store (ADR-0007).
 */
import { Module } from '@nestjs/common';
import { DatabaseModule } from '../db/database.module.js';
import { MediaModule } from '../media/media.module.js';
import { MEDIA_STORAGE } from '../media/media.storage.js';
import { EXPORT_ARTIFACT_STORAGE } from './export-artifact.storage.js';
import { ExportsStore } from './exports.store.js';

@Module({
  imports: [DatabaseModule, MediaModule],
  providers: [
    ExportsStore,
    { provide: EXPORT_ARTIFACT_STORAGE, useExisting: MEDIA_STORAGE },
  ],
  exports: [ExportsStore, EXPORT_ARTIFACT_STORAGE],
})
export class ExportsModule {}
