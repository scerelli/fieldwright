import { Logger } from '@nestjs/common';
import { Worker, type Job, type Processor } from 'bullmq';
import { pathToFileURL } from 'node:url';
import { createRedisConnection } from './queue/redis.provider.js';

export const WORKER_QUEUE_NAME = 'exports';

const logger = new Logger('Worker');

export function createWorker(
  redisUrl: string | undefined,
  processor: Processor,
  queueName: string = WORKER_QUEUE_NAME,
): Worker {
  const connection = createRedisConnection(redisUrl);

  return new Worker(queueName, processor, { connection });
}

export async function processJob(job: Job): Promise<void> {
  logger.debug(
    `received job ${job.id} (${job.name}) on the ${WORKER_QUEUE_NAME} queue`,
  );
}

const isMainModule =
  process.argv[1] !== undefined &&
  import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMainModule) {
  createWorker(process.env.REDIS_URL, processJob);
}
