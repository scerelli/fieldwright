import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DatabaseModule } from '../db/database.module.js';
import { SurveyPeriodsController } from './survey-periods.controller.js';
import { SurveyPeriodsService } from './survey-periods.service.js';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [SurveyPeriodsController],
  providers: [SurveyPeriodsService],
})
export class SurveyPeriodsModule {}
