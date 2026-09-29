import type { INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { Server } from 'node:http';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { AppModule } from '../src/app.module.js';
import { HealthService } from '../src/health/health.service.js';

describe('health endpoints', () => {
  let app: INestApplication;
  let baseUrl: string;

  beforeEach(async () => {
    app = await NestFactory.create(AppModule, { logger: false });
    await app.listen(0, '127.0.0.1');
    const server = app.getHttpServer() as Server;
    const address = server.address();
    if (address === null || typeof address === 'string') {
      throw new Error('server did not bind to a TCP port');
    }
    baseUrl = `http://127.0.0.1:${address.port}`;
  });

  afterEach(async () => {
    await app.close();
  });

  it('GET /healthz returns 200', async () => {
    const response = await fetch(`${baseUrl}/healthz`);

    expect(response.status).toBe(200);
  });

  it('GET /readyz returns 200 when every registered dependency is healthy', async () => {
    app.get(HealthService).register('database', () => true);

    const response = await fetch(`${baseUrl}/readyz`);

    expect(response.status).toBe(200);
  });

  it('GET /readyz returns 503 when any registered dependency is unhealthy', async () => {
    app.get(HealthService).register('database', () => true);
    app.get(HealthService).register('redis', () => false);

    const response = await fetch(`${baseUrl}/readyz`);

    expect(response.status).toBe(503);
  });

  it('GET /readyz returns 503 when a registered dependency throws', async () => {
    app.get(HealthService).register('broken', () => {
      throw new Error('dependency check failed');
    });

    const response = await fetch(`${baseUrl}/readyz`);

    expect(response.status).toBe(503);
  });

  it('adds a readiness dependency through the registry without editing the controller', async () => {
    app.get(HealthService).register('later-module', () => true);

    const response = await fetch(`${baseUrl}/readyz`);
    const body = (await response.json()) as {
      dependencies: Record<string, boolean>;
    };

    expect(response.status).toBe(200);
    expect(body.dependencies).toEqual({ 'later-module': true });
  });
});
