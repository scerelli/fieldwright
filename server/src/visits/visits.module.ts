import { Module } from '@nestjs/common';
import { DatabaseModule } from '../db/database.module.js';
import { VisitsService } from './visits.service.js';

@Module({
  imports: [DatabaseModule],
  providers: [VisitsService],
  exports: [VisitsService],
})
export class VisitsModule {}
