/**
 * The server `projects` module's REST surface (ARCHITECTURE.md). `POST
 * /projects` is auth-guarded: the creator resolved by `AuthGuard` becomes the
 * Project's creator Membership. `POST /projects/:projectId/members` is
 * auth-guarded too and only the Project's creator may grant a collector or
 * validator Membership. `GET /projects/:projectId/members` is auth-guarded and
 * returns the Project's Memberships to any member of that Project.
 */
import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import {
  IsBoolean,
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsString,
} from 'class-validator';
import { AuthGuard, type Person } from '../auth/auth.guard.js';
import { CurrentPerson } from '../auth/current-person.decorator.js';
import {
  ProjectsService,
  type AddMemberInput,
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

export class AddMemberDto implements AddMemberInput {
  @IsEmail()
  email!: string;

  @IsIn(['collector', 'validator'])
  role!: AddMemberInput['role'];
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

  @UseGuards(AuthGuard)
  @Get(':projectId/members')
  listMembers(
    @CurrentPerson() person: Person,
    @Param('projectId', ParseUUIDPipe) projectId: string,
  ) {
    return this.projects.listMembers(person.id, projectId);
  }

  @UseGuards(AuthGuard)
  @Post(':projectId/members')
  addMember(
    @CurrentPerson() person: Person,
    @Param('projectId', ParseUUIDPipe) projectId: string,
    @Body() dto: AddMemberDto,
  ) {
    return this.projects.addMember(person.id, projectId, dto);
  }
}
