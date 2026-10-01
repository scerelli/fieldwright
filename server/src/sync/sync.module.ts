/**
 * The server `sync` module (ARCHITECTURE.md): the versioned transport under
 * `/api/v1`. It owns no aggregate; the config pull reads Project configuration
 * owned by the projects and sites modules and serves it to a Member of that
 * Project.
 */
import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DatabaseModule } from '../db/database.module.js';
import { ConfigController } from './config.controller.js';
import { ConfigService } from './config.service.js';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [ConfigController],
  providers: [ConfigService],
})
export class SyncModule {}
