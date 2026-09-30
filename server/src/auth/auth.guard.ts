/**
 * The server `identity` module's guard (ARCHITECTURE.md): validates
 * authentication on protected routes, rejects an unauthenticated request with
 * a 401, and attaches the current person and their project Memberships to the
 * request for `@CurrentPerson()`. Routes opt in with `@UseGuards(AuthGuard)`.
 */
import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { fromNodeHeaders } from 'better-auth/node';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { Request } from 'express';
import { DATABASE } from '../db/database.provider.js';
import { membership, type Membership } from '../db/schema.js';
import type { Auth } from './auth.module.js';

/**
 * Injection token for the Better Auth instance. It lives here rather than in
 * `auth.module.ts` so the guard can inject it without the module and the guard
 * importing each other; `AuthModule` re-exports it.
 */
export const AUTH = 'AUTH';

export type Person = Auth['$Infer']['Session']['user']; // glossary:allow Better Auth's auth-session type, not the Visit

export interface AuthenticatedRequest extends Request {
  currentPerson?: Person;
  currentMemberships?: Membership[];
}

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    @Inject(AUTH) private readonly auth: Auth,
    @Inject(DATABASE) private readonly db: NodePgDatabase,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();

    const headers = fromNodeHeaders(request.headers);
    const result = await this.auth.api.getSession({ headers }); // glossary:allow Better Auth's auth-session, not the Visit

    if (result === null) {
      throw new UnauthorizedException();
    }

    request.currentPerson = result.user;
    request.currentMemberships = await this.db
      .select()
      .from(membership)
      .where(eq(membership.personId, result.user.id));

    return true;
  }
}
