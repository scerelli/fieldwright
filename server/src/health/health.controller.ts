import {
  Controller,
  Get,
  Inject,
  ServiceUnavailableException,
} from '@nestjs/common';
import { HealthService } from './health.service.js';

@Controller()
export class HealthController {
  constructor(@Inject(HealthService) private readonly health: HealthService) {}

  @Get('healthz')
  healthz(): { status: string } {
    return { status: 'ok' };
  }

  @Get('readyz')
  async readyz(): Promise<{
    status: string;
    dependencies: Record<string, boolean>;
  }> {
    const { healthy, dependencies } = await this.health.check();

    if (!healthy) {
      throw new ServiceUnavailableException({ status: 'error', dependencies });
    }

    return { status: 'ok', dependencies };
  }
}
