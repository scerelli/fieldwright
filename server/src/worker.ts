import { NestFactory } from '@nestjs/core';
import type { INestApplicationContext } from '@nestjs/common';
import { Worker, type Processor } from 'bullmq';
import { pathToFileURL } from 'node:url';
import { ExportProcessor } from './exports/export.processor.js';
import { createRedisConnection } from './queue/redis.provider.js';

export const WORKER_QUEUE_NAME = 'exports';

export function createWorker(
  redisUrl: string | undefined,
  processor: Processor,
  queueName: string = WORKER_QUEUE_NAME,
): Worker {
  const connection = createRedisConnection(redisUrl);

  return new Worker(queueName, processor, { connection });
}

/**
 * Binds the worker entry point's processor for the `exports` queue to the
 * `exports` module's `ExportProcessor` (ARCHITECTURE.md, ADR-0008): the same
 * server image runs this as its second process, consuming the jobs the API
 * enqueues onto `WORKER_QUEUE_NAME`.
 */
export function createExportWorker(
  app: INestApplicationContext,
  redisUrl: string | undefined,
): Worker {
  const processor = app.get(ExportProcessor);
  return createWorker(redisUrl, (job) => processor.process(job));
}

const isMainModule =
  process.argv[1] !== undefined &&
  import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMainModule) {
  const { AppModule } = await import('./app.module.js');
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: false,
  });
  createExportWorker(app, process.env.REDIS_URL);
}
