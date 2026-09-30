/**
 * The server `projects` module's REST surface (ARCHITECTURE.md). `POST
 * /projects` is auth-guarded: the creator resolved by `AuthGuard` becomes the
 * Project's creator Membership.
 */
import {
  Body,
  Controller,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { IsBoolean, IsNotEmpty, IsString } from 'class-validator';
import { AuthGuard, type Person } from '../auth/auth.guard.js';
import { CurrentPerson } from '../auth/current-person.decorator.js';
import {
  ProjectsService,
  type CreateProjectInput,
} from './projects.service.js';

export class CreateProjectDto implements CreateProjectInput {
  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsBoolean()
  validationEnabled!: boolean;

  @IsBoolean()
  sensitiveTaxaObfuscation!: boolean;

  @IsString()
  @IsNotEmpty()
  taxonomicReferenceId!: string;

  @IsString()
  @IsNotEmpty()
  taxonomicReferenceVersion!: string;
}

@Controller('projects')
@UsePipes(
  new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
  }),
)
export class ProjectsController {
  constructor(private readonly projects: ProjectsService) {}

  @UseGuards(AuthGuard)
  @Post()
  create(@CurrentPerson() person: Person, @Body() dto: CreateProjectDto) {
    return this.projects.create(person.id, dto);
  }
}
