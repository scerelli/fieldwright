import type { INestApplication } from '@nestjs/common';
import { Module } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import {
  RedisContainer,
  type StartedRedisContainer,
} from '@testcontainers/redis';
import { Redis } from 'ioredis';
import type { Server } from 'node:http';
import { once } from 'node:events';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { HealthModule } from '../src/health/health.module.js';
import { QueueModule } from '../src/queue/queue.module.js';
import { REDIS, createRedisConnection } from '../src/queue/redis.provider.js';

@Module({ imports: [HealthModule, QueueModule] })
class QueueTestModule {}

describe('createRedisConnection', () => {
  it('builds an ioredis client from a connection string', () => {
    const redis = createRedisConnection('redis://:secret@redis.example:6380/3');

    expect(redis).toBeInstanceOf(Redis);
    expect(redis.options.host).toBe('redis.example');
    expect(redis.options.port).toBe(6380);
    expect(redis.options.db).toBe(3);
    expect(redis.options.maxRetriesPerRequest).toBeNull();

    redis.disconnect();
  });

  it('fails loud when the connection string is missing', () => {
    expect(() => createRedisConnection(undefined)).toThrow(/REDIS_URL/);
  });
});

describe('QueueModule readiness', () => {
  let container: StartedRedisContainer;

  beforeAll(async () => {
    container = await new RedisContainer('redis:7').start();
  }, 120_000);

  afterAll(async () => {
    await container.stop();
  });

  describe('with a reachable Redis', () => {
    let app: INestApplication;
    let baseUrl: string;

    beforeAll(async () => {
      process.env.REDIS_URL = container.getConnectionUrl();
      app = await NestFactory.create(QueueTestModule, { logger: false });
      await app.listen(0, '127.0.0.1');
      baseUrl = baseUrlOf(app);
    });

    afterAll(async () => {
      await app.close();
    });

    it('builds the Redis connection from REDIS_URL', () => {
      const redis = app.get<Redis>(REDIS);

      expect(redis).toBeInstanceOf(Redis);
      expect(redis.options.host).toBe('localhost');
      expect(redis.options.port).toBe(container.getPort());
    });

    it('GET /readyz returns 200 when Redis is reachable', async () => {
      const redis = app.get<Redis>(REDIS);
      if (redis.status !== 'ready') {
        await once(redis, 'ready');
      }

      const response = await fetch(`${baseUrl}/readyz`);
      const body = (await response.json()) as {
        dependencies: Record<string, boolean>;
      };

      expect(response.status).toBe(200);
      expect(body.dependencies.redis).toBe(true);
    });
  });

  describe('with an unreachable Redis', () => {
    let app: INestApplication;
    let baseUrl: string;

    beforeAll(async () => {
      const dead = await new RedisContainer('redis:7').start();
      const deadUrl = dead.getConnectionUrl();
      await dead.stop();

      process.env.REDIS_URL = deadUrl;
      app = await NestFactory.create(QueueTestModule, { logger: false });
      await app.listen(0, '127.0.0.1');
      baseUrl = baseUrlOf(app);
    }, 120_000);

    afterAll(async () => {
      await app.close();
    });

    it('GET /readyz returns 503 when Redis is unreachable', async () => {
      const response = await fetch(`${baseUrl}/readyz`);
      const body = (await response.json()) as {
        dependencies: Record<string, boolean>;
      };

      expect(response.status).toBe(503);
      expect(body.dependencies.redis).toBe(false);
    });
  });
});

function baseUrlOf(app: INestApplication): string {
  const server = app.getHttpServer() as Server;
  const address = server.address();
  if (address === null || typeof address === 'string') {
    throw new Error('server did not bind to a TCP port');
  }
  return `http://127.0.0.1:${address.port}`;
}
