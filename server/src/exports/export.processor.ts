/**
 * The `exports` module's job processor (ARCHITECTURE.md, ADR-0008): the
 * worker-side half of an Export. It resolves the export record, dispatches to
 * the `ExportGenerator` registered for the record's format, writes the produced
 * bytes through the export artifact store, and marks the record `succeeded`.
 * When the generator throws the job is left to BullMQ's retry; on the final
 * attempt (the job's configured `attempts` cap) the record is marked `failed`
 * with the error. The generator registry is the seam the format siblings
 * (#46–#49) and #50's role-based obfuscation plug into: a generator produces
 * the artifact bytes with any sensitive-coordinate obfuscation already applied
 * (INV-011), so unobfuscated coordinates are never written.
 */
import { Inject, Injectable } from '@nestjs/common';
import type { Job } from 'bullmq';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import { exportRecord, type Export } from '../db/schema.js';
import {
  EXPORT_ARTIFACT_STORAGE,
  type ExportArtifactStorage,
} from './export-artifact.storage.js';
import type { ExportJobData } from './exports.queue.js';
import { ExportsStore } from './exports.store.js';

/**
 * A format generator: one Export format's artifact producer. Each format
 * (#46–#49) registers one; sensitive-coordinate obfuscation (#50) is applied
 * inside `generate`, before the bytes are returned for storage (INV-011).
 */
export interface ExportGenerator {
  /** The Export format this generator produces. */
  readonly format: string;
  /** Produces the Export's artifact bytes, obfuscation included (INV-011). */
  generate(exportRecord: Export): Promise<Uint8Array>;
}

/** DI token for the `ExportGenerator`s the `exports` module can dispatch to. */
export const EXPORT_GENERATORS = 'EXPORT_GENERATORS';

/**
 * The attempt cap an Export job runs under when its enqueuer configured none.
 * BullMQ reads a job's `attempts` when it decides whether to retry, so the
 * worker applies this default before running the generator; a cap the enqueuer
 * did set always wins.
 */
export const EXPORT_JOB_ATTEMPTS = 4;

/** Resolves the `ExportGenerator` registered for an Export's format. */
@Injectable()
export class ExportGeneratorRegistry {
  constructor(
    @Inject(EXPORT_GENERATORS)
    private readonly generators: ExportGenerator[],
  ) {}

  /** Returns the generator for `format`, or throws when none is registered. */
  resolve(format: string): ExportGenerator {
    const found = this.generators.find(
      (generator) => generator.format === format,
    );
    if (found === undefined) {
      throw new Error(`no Export generator is registered for format ${format}`);
    }
    return found;
  }
}

@Injectable()
export class ExportProcessor {
  constructor(
    @Inject(DATABASE) private readonly db: NodePgDatabase,
    private readonly exports: ExportsStore,
    private readonly generators: ExportGeneratorRegistry,
    @Inject(EXPORT_ARTIFACT_STORAGE)
    private readonly artifacts: ExportArtifactStorage,
  ) {}

  /**
   * Processes one Export job. The job's configured attempt cap — or the
   * worker's default when the enqueuer set none — is applied first, because
   * BullMQ reads it off the job when deciding whether to retry. A thrown error
   * is left to propagate, so BullMQ retries up to that cap; the record is
   * marked `failed` only on the final attempt, so a transient failure that
   * later succeeds never leaves a failed export behind.
   */
  async process(job: Job<ExportJobData>): Promise<void> {
    const cap = Math.max(job.opts.attempts || EXPORT_JOB_ATTEMPTS, 1);
    job.opts.attempts = cap;

    const found = await this.exports.findById(job.data.exportId);
    if (found === null) {
      throw new Error(`Export ${job.data.exportId} does not exist`);
    }

    try {
      const generator = this.generators.resolve(found.format);
      const bytes = await generator.generate(found);
      const storageKey = await this.artifacts.put(bytes);
      await this.markSucceeded(found.id, storageKey);
    } catch (error) {
      if (job.attemptsMade + 1 >= cap) {
        await this.markFailed(found.id, messageOf(error));
      }
      throw error;
    }
  }

  private async markSucceeded(
    exportId: string,
    storageKey: string,
  ): Promise<void> {
    await this.db
      .update(exportRecord)
      .set({ state: 'succeeded', storageKey, error: null })
      .where(eq(exportRecord.id, exportId));
  }

  private async markFailed(exportId: string, error: string): Promise<void> {
    await this.db
      .update(exportRecord)
      .set({ state: 'failed', error })
      .where(eq(exportRecord.id, exportId));
  }
}

/** A thrown value's message, so the Export records a readable error. */
function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
