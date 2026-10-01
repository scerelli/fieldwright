/**
 * The `exports` module's queue surface (ARCHITECTURE.md, ADR-0008): the
 * API-side enqueue of one Export job. It wraps the BullMQ `exports` queue the
 * `queue` module registers so the request path names the job and its payload in
 * one place; the `worker` process consumes it. A job carries the Export id and
 * its requested format, which is all the job needs to produce the artifact.
 */
import { Inject, Injectable } from '@nestjs/common';
import type { Queue } from 'bullmq';
import { EXPORTS_QUEUE } from '../queue/queue.module.js';

export { EXPORTS_QUEUE };

/** The payload one Export job carries: the Export id and its requested format. */
export interface ExportJobData {
  exportId: string;
  format: string;
}

/** The job name the `worker` process consumes for an Export. */
export const EXPORT_JOB_NAME = 'generate-export';

@Injectable()
export class ExportsQueue {
  constructor(
    @Inject(EXPORTS_QUEUE) private readonly queue: Queue<ExportJobData>,
  ) {}

  /** Enqueues exactly one Export job for the given payload. */
  async enqueue(data: ExportJobData): Promise<void> {
    await this.queue.add(EXPORT_JOB_NAME, data);
  }
}
