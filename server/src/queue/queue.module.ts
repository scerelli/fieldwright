import type { OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Inject, Module } from '@nestjs/common';
import type { Redis } from 'ioredis';
import { HealthModule } from '../health/health.module.js';
import { HealthService } from '../health/health.service.js';
import {
  REDIS,
  createRedisHealthIndicator,
  redisProvider,
} from './redis.provider.js';

@Module({
  imports: [HealthModule],
  providers: [redisProvider],
  exports: [REDIS],
})
export class QueueModule implements OnModuleInit, OnModuleDestroy {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    private readonly health: HealthService,
  ) {}

  onModuleInit(): void {
    this.health.register('redis', createRedisHealthIndicator(this.redis));
  }

  onModuleDestroy(): void {
    this.redis.disconnect();
  }
}
