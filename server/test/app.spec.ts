import { NestFactory } from '@nestjs/core';
import { describe, expect, it } from 'vitest';
import { AppModule } from '../src/app.module.js';

describe('AppModule', () => {
  it('boots the application without error', async () => {
    process.env.DATABASE_URL = 'postgres://ibis:ibis@127.0.0.1:5432/ibis';
    process.env.REDIS_URL = 'redis://127.0.0.1:6379';
    process.env.BETTER_AUTH_SECRET =
      'test-only-secret-at-least-thirty-two-characters';

    const app = await NestFactory.create(AppModule, { logger: false });

    expect(app.getHttpServer()).toBeDefined();

    await app.close();
  });
});
