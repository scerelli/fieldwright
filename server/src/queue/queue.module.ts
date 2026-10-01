/**
 * The server `queue` module (ARCHITECTURE.md, ADR-0008): the shared Redis
 * connection and the BullMQ `exports` queue the API enqueues one Export job
 * onto. The connection is also the readiness check's Redis probe; the queue
 * carries the same name the `worker` process consumes (`WORKER_QUEUE_NAME`), so
 * the two sides cannot drift.
 */
import type { OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Inject, Module } from '@nestjs/common';
import { Queue } from 'bullmq';
import type { Redis } from 'ioredis';
import { HealthModule } from '../health/health.module.js';
import { HealthService } from '../health/health.service.js';
import { WORKER_QUEUE_NAME } from '../worker.js';
import {
  REDIS,
  createRedisHealthIndicator,
  redisProvider,
} from './redis.provider.js';

/** DI token for the BullMQ `exports` queue the API enqueues Export jobs onto. */
export const EXPORTS_QUEUE = 'EXPORTS_QUEUE';

@Module({
  imports: [HealthModule],
  providers: [
    redisProvider,
    {
      provide: EXPORTS_QUEUE,
      useFactory: (redis: Redis): Queue =>
        new Queue(WORKER_QUEUE_NAME, { connection: redis }),
      inject: [REDIS],
    },
  ],
  exports: [REDIS, EXPORTS_QUEUE],
})
export class QueueModule implements OnModuleInit, OnModuleDestroy {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(EXPORTS_QUEUE) private readonly exportsQueue: Queue,
    private readonly health: HealthService,
  ) {}

  onModuleInit(): void {
    this.health.register('redis', createRedisHealthIndicator(this.redis));
  }

  async onModuleDestroy(): Promise<void> {
    await this.exportsQueue.close();
    this.redis.disconnect();
  }
}
