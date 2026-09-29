import { Injectable } from '@nestjs/common';

export type HealthIndicator = () => boolean | Promise<boolean>;

export interface ReadinessResult {
  healthy: boolean;
  dependencies: Record<string, boolean>;
}

@Injectable()
export class HealthService {
  private readonly indicators = new Map<string, HealthIndicator>();

  register(name: string, indicator: HealthIndicator): void {
    this.indicators.set(name, indicator);
  }

  async check(): Promise<ReadinessResult> {
    const dependencies: Record<string, boolean> = {};
    let healthy = true;

    for (const [name, indicator] of this.indicators) {
      const result = await this.run(indicator);
      dependencies[name] = result;
      healthy = healthy && result;
    }

    return { healthy, dependencies };
  }

  private async run(indicator: HealthIndicator): Promise<boolean> {
    try {
      return await indicator();
    } catch {
      return false;
    }
  }
}
