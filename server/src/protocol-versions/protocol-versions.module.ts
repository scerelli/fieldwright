import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DatabaseModule } from '../db/database.module.js';
import { ProtocolVersionsController } from './protocol-versions.controller.js';
import { ProtocolVersionsService } from './protocol-versions.service.js';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [ProtocolVersionsController],
  providers: [ProtocolVersionsService],
})
export class ProtocolVersionsModule {}
