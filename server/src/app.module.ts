/**
 * The served application's root module (ARCHITECTURE.md): wires the database,
 * queue, identity, projects and survey-periods modules so the running server
 * exposes the auth, projects and survey-periods endpoints and its readiness
 * check reflects Postgres and Redis.
 *
 * Connection strings and secrets come from the environment (`DATABASE_URL`,
 * `REDIS_URL`, `BETTER_AUTH_SECRET`), as the Compose deployment supplies them.
 */
import { Inject, Module, type OnApplicationBootstrap } from '@nestjs/common';
import { AuthModule } from './auth/auth.module.js';
import { DatabaseModule } from './db/database.module.js';
import { QUERY_EXECUTOR, type QueryExecutor } from './db/database.provider.js';
import { HealthModule } from './health/health.module.js';
import { HealthService } from './health/health.service.js';
import { ProjectsModule } from './projects/projects.module.js';
import { QueueModule } from './queue/queue.module.js';
import { SurveyPeriodsModule } from './survey-periods/survey-periods.module.js';

@Module({
  imports: [
    DatabaseModule,
    QueueModule,
    AuthModule,
    ProjectsModule,
    SurveyPeriodsModule,
    HealthModule,
  ],
})
export class AppModule implements OnApplicationBootstrap {
  constructor(
    @Inject(QUERY_EXECUTOR) private readonly executor: QueryExecutor,
    private readonly health: HealthService,
  ) {}

  onApplicationBootstrap(): void {
    this.health.register('database', () => this.isDatabaseReachable());
  }

  private async isDatabaseReachable(): Promise<boolean> {
    const result = await this.executor.query('SELECT 1');
    return result.rows.length === 1;
  }
}
