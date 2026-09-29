import { Queue, Worker } from 'bullmq';
import type { Job } from 'bullmq';
import {
  RedisContainer,
  type StartedRedisContainer,
} from '@testcontainers/redis';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createRedisConnection } from '../src/queue/redis.provider.js';
import { WORKER_QUEUE_NAME, createWorker } from '../src/worker.js';

describe('worker entry point', () => {
  let container: StartedRedisContainer;
  let redisUrl: string;

  beforeAll(async () => {
    container = await new RedisContainer('redis:7').start();
    redisUrl = container.getConnectionUrl();
  }, 120_000);

  afterAll(async () => {
    await container.stop();
  });

  it('consumes the exports queue', () => {
    expect(WORKER_QUEUE_NAME).toBe('exports');
  });

  it('fails loud when the connection string is missing', () => {
    expect(() => createWorker(undefined, async () => undefined)).toThrow(
      /REDIS_URL/,
    );
  });

  it('starts a BullMQ Worker bound to the queue', async () => {
    const worker = createWorker(redisUrl, async () => undefined);

    try {
      await worker.waitUntilReady();

      expect(worker).toBeInstanceOf(Worker);
      expect(worker.name).toBe(WORKER_QUEUE_NAME);
      expect(worker.isRunning()).toBe(true);
    } finally {
      await worker.close();
    }
  }, 30_000);

  it('processes a job enqueued on Redis', async () => {
    const connection = createRedisConnection(redisUrl);
    const queue = new Queue(WORKER_QUEUE_NAME, { connection });

    let resolveHandled!: () => void;
    const handled = new Promise<void>((resolve) => {
      resolveHandled = resolve;
    });
    let seen: { name: string; data: unknown } | undefined;

    const worker = createWorker(redisUrl, async (job: Job) => {
      seen = { name: job.name, data: job.data };
      resolveHandled();
      return 'processed';
    });

    try {
      await worker.waitUntilReady();
      await queue.add('generate-export', { format: 'csv', projectId: 'p1' });
      await handled;

      expect(seen).toEqual({
        name: 'generate-export',
        data: { format: 'csv', projectId: 'p1' },
      });
    } finally {
      await worker.close();
      await queue.close();
      await connection.quit();
    }
  }, 30_000);
});
