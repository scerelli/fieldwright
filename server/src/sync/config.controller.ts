/**
 * The server `sync` module's versioned config pull (ARCHITECTURE.md,
 * ADR-0011). `GET /api/v1/projects/:projectId/config?since=` is auth-guarded
 * and scoped to Projects the current person is a Member of. The response
 * carries the `versionToken` to send on the next pull plus what changed since
 * the supplied one; a request with an unknown query parameter is accepted and
 * the parameter ignored, as the `/api/v1` surface is additive only.
 */
import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard, type Person } from '../auth/auth.guard.js';
import { CurrentPerson } from '../auth/current-person.decorator.js';
import { ConfigService, type ConfigPull } from './config.service.js';

@Controller('api/v1/projects')
export class ConfigController {
  constructor(private readonly config: ConfigService) {}

  @UseGuards(AuthGuard)
  @Get(':projectId/config')
  pull(
    @CurrentPerson() person: Person,
    @Param('projectId', ParseUUIDPipe) projectId: string,
    @Query('since') since?: string,
  ): Promise<ConfigPull> {
    return this.config.pull(person.id, projectId, since);
  }
}
