/**
 * Parameter decorators that expose what `AuthGuard` resolved for the current
 * request: the person and their project Memberships. Use on a route guarded by
 * `AuthGuard`.
 */
import { createParamDecorator, type ExecutionContext } from '@nestjs/common';
import type { AuthenticatedRequest, Person } from './auth.guard.js';
import type { Membership } from '../db/schema.js';

export const CurrentPerson = createParamDecorator(
  (_data: unknown, context: ExecutionContext): Person => {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    return request.currentPerson as Person;
  },
);

export const CurrentMemberships = createParamDecorator(
  (_data: unknown, context: ExecutionContext): Membership[] => {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    return request.currentMemberships ?? [];
  },
);
