/**
 * The server `protocol-versions` module's REST surface (ARCHITECTURE.md). Both
 * endpoints are auth-guarded and act only on Projects the current person is a
 * member of. There is deliberately no update route: a frozen version is
 * immutable (INV-007), so a change is submitted as a new version instead.
 */
import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { IsObject, IsUUID } from 'class-validator';
import { AuthGuard, type Person } from '../auth/auth.guard.js';
import { CurrentPerson } from '../auth/current-person.decorator.js';
import {
  ProtocolVersionsService,
  type CreateProtocolVersionInput,
} from './protocol-versions.service.js';

export class CreateProtocolVersionDto implements CreateProtocolVersionInput {
  @IsUUID()
  projectId!: string;

  @IsObject()
  document!: Record<string, unknown>;
}

@Controller('protocol-versions')
@UsePipes(
  new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
  }),
)
export class ProtocolVersionsController {
  constructor(private readonly protocolVersions: ProtocolVersionsService) {}

  @UseGuards(AuthGuard)
  @Post()
  create(
    @CurrentPerson() person: Person,
    @Body() dto: CreateProtocolVersionDto,
  ) {
    return this.protocolVersions.create(person.id, dto);
  }

  @UseGuards(AuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post(':id/freeze')
  freeze(
    @CurrentPerson() person: Person,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.protocolVersions.freeze(person.id, id);
  }
}
