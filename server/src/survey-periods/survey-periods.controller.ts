/**
 * The server `survey-periods` module's REST surface (ARCHITECTURE.md). Both
 * endpoints are auth-guarded: a Project's creator defines a Survey period with
 * `POST /survey-periods`, and a Project member lists them with
 * `GET /survey-periods?projectId=`.
 */
import {
  Body,
  Controller,
  Get,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { IsNotEmpty, IsString, IsUUID, Matches } from 'class-validator';
import { AuthGuard, type Person } from '../auth/auth.guard.js';
import { CurrentPerson } from '../auth/current-person.decorator.js';
import {
  SurveyPeriodsService,
  type CreateSurveyPeriodInput,
} from './survey-periods.service.js';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

export class CreateSurveyPeriodDto implements CreateSurveyPeriodInput {
  @IsUUID()
  projectId!: string;

  @IsString()
  @IsNotEmpty()
  name!: string;

  @Matches(ISO_DATE)
  startDate!: string;

  @Matches(ISO_DATE)
  endDate!: string;
}

@Controller('survey-periods')
@UsePipes(
  new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
  }),
)
export class SurveyPeriodsController {
  constructor(private readonly surveyPeriods: SurveyPeriodsService) {}

  @UseGuards(AuthGuard)
  @Post()
  create(@CurrentPerson() person: Person, @Body() dto: CreateSurveyPeriodDto) {
    return this.surveyPeriods.create(person.id, dto);
  }

  @UseGuards(AuthGuard)
  @Get()
  list(
    @CurrentPerson() person: Person,
    @Query('projectId', new ParseUUIDPipe()) projectId: string,
  ) {
    return this.surveyPeriods.list(person.id, projectId);
  }
}
