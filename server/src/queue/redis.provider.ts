import type { Provider } from '@nestjs/common';
import { Redis } from 'ioredis';
import type { HealthIndicator } from '../health/health.service.js';

export const REDIS = 'REDIS';

const PING_TIMEOUT_MS = 1000;

export function createRedisConnection(redisUrl: string | undefined): Redis {
  if (redisUrl === undefined || redisUrl === '') {
    throw new Error(
      'REDIS_URL is not set: the queue module needs a Redis connection string',
    );
  }

  const client = new Redis(redisUrl, { maxRetriesPerRequest: null });
  client.on('error', () => undefined);

  return client;
}

export function createRedisHealthIndicator(redis: Redis): HealthIndicator {
  return () => redis.status === 'ready' && ping(redis, PING_TIMEOUT_MS);
}

function ping(redis: Redis, timeoutMs: number): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    const timer = setTimeout(() => resolve(false), timeoutMs);
    redis.ping().then(
      (reply) => {
        clearTimeout(timer);
        resolve(reply === 'PONG');
      },
      () => {
        clearTimeout(timer);
        resolve(false);
      },
    );
  });
}

export const redisProvider: Provider = {
  provide: REDIS,
  useFactory: () => createRedisConnection(process.env.REDIS_URL),
};
