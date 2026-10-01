/**
 * The server `exports` module (ARCHITECTURE.md): the durable Export records,
 * the request/serve API and the BullMQ `exports` queue the API enqueues a job
 * onto, plus the artifact storage the generator writes to and the API reads
 * back from. It binds `EXPORT_ARTIFACT_STORAGE` to the media backend the
 * `media` module serves from, so a worker writes an Export artifact to the same
 * content-addressed volume or S3 Store (ADR-0007, ADR-0008).
 */
import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DatabaseModule } from '../db/database.module.js';
import { MediaModule } from '../media/media.module.js';
import { MEDIA_STORAGE } from '../media/media.storage.js';
import { QueueModule } from '../queue/queue.module.js';
import { EXPORT_ARTIFACT_STORAGE } from './export-artifact.storage.js';
import {
  EXPORT_GENERATORS,
  ExportGeneratorRegistry,
  ExportProcessor,
} from './export.processor.js';
import { ExportsController } from './exports.controller.js';
import { ExportsQueue } from './exports.queue.js';
import { ExportsService } from './exports.service.js';
import { ExportsStore } from './exports.store.js';

@Module({
  imports: [DatabaseModule, MediaModule, QueueModule, AuthModule],
  controllers: [ExportsController],
  providers: [
    ExportsStore,
    ExportsQueue,
    ExportsService,
    ExportGeneratorRegistry,
    ExportProcessor,
    { provide: EXPORT_ARTIFACT_STORAGE, useExisting: MEDIA_STORAGE },
    // The generator registry seam: the format siblings (#46–#49) each add
    // their `ExportGenerator` here, and #50's role-based obfuscation plugs into
    // the same seam, applied inside a generator before bytes are stored.
    { provide: EXPORT_GENERATORS, useValue: [] },
  ],
  exports: [ExportsStore, ExportProcessor, EXPORT_ARTIFACT_STORAGE],
})
export class ExportsModule {}
