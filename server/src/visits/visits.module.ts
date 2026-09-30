import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DatabaseModule } from '../db/database.module.js';
import { VisitsController } from './visits.controller.js';
import { VisitsService } from './visits.service.js';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [VisitsController],
  providers: [VisitsService],
  exports: [VisitsService],
})
export class VisitsModule {}
