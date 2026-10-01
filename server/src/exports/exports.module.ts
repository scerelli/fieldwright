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
  type ExportGenerator,
} from './export.processor.js';
import { buildDetectionHistoryMatrix } from './detection-history.js';
import {
  DETECTION_HISTORY_BUILDER,
  DetectionHistoryGenerator,
} from './detection-history.generator.js';
import { ExportsController } from './exports.controller.js';
import { ExportsQueue } from './exports.queue.js';
import { ExportsService } from './exports.service.js';
import { ExportsStore } from './exports.store.js';

/**
 * Assembles the registered `ExportGenerator`s from the ones the module injects.
 * A factory — not a fixed `useValue` array — is the composable seam: each
 * format sibling (#46–#49) adds its generator to the `inject` list without
 * clobbering the others, and every injected generator stays resolvable.
 */
export function exportGeneratorsFactory(
  ...generators: ExportGenerator[]
): ExportGenerator[] {
  return generators;
}

@Module({
  imports: [DatabaseModule, MediaModule, QueueModule, AuthModule],
  controllers: [ExportsController],
  providers: [
    ExportsStore,
    ExportsQueue,
    ExportsService,
    ExportGeneratorRegistry,
    ExportProcessor,
    DetectionHistoryGenerator,
    { provide: EXPORT_ARTIFACT_STORAGE, useExisting: MEDIA_STORAGE },
    { provide: DETECTION_HISTORY_BUILDER, useValue: buildDetectionHistoryMatrix },
    // The generator registry seam: the format siblings (#46–#49) each add
    // their `ExportGenerator` to the factory's `inject` list, and #50's
    // role-based obfuscation plugs into the same seam inside a generator,
    // applied before bytes are stored.
    {
      provide: EXPORT_GENERATORS,
      useFactory: exportGeneratorsFactory,
      inject: [DetectionHistoryGenerator],
    },
  ],
  exports: [ExportsStore, ExportProcessor, EXPORT_ARTIFACT_STORAGE],
})
export class ExportsModule {}
