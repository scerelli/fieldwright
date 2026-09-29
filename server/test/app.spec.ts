import { NestFactory } from '@nestjs/core';
import { describe, expect, it } from 'vitest';
import { AppModule } from '../src/app.module.js';

describe('AppModule', () => {
  it('boots the application without error', async () => {
    const app = await NestFactory.create(AppModule, { logger: false });

    expect(app.getHttpServer()).toBeDefined();

    await app.close();
  });
});
