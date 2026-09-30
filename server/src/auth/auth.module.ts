/**
 * Better Auth integration (ADR-0003).
 *
 * Owns the auth schema's runtime: it wires Better Auth's Drizzle adapter over
 * the shared Drizzle instance and mounts its REST handler at `/api/auth/*`.
 * Roles are project-scoped Memberships in the domain, so this module only
 * identifies a person; it never carries authorization.
 */
import { All, Controller, Inject, Module, Req, Res } from '@nestjs/common';
import type { Provider } from '@nestjs/common';
import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import { toNodeHandler } from 'better-auth/node';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { Request, Response } from 'express';
import { DATABASE } from '../db/database.provider.js';
import { DatabaseModule } from '../db/database.module.js';
import * as schema from '../db/schema.js';

export const AUTH = 'AUTH';

export function createAuth(db: NodePgDatabase) {
  return betterAuth({
    database: drizzleAdapter(db, { provider: 'pg', schema }),
    emailAndPassword: { enabled: true },
    secret: process.env.BETTER_AUTH_SECRET,
    baseURL: process.env.BETTER_AUTH_URL,
  });
}

export type Auth = ReturnType<typeof createAuth>;

export const authProvider: Provider = {
  provide: AUTH,
  useFactory: (db: NodePgDatabase) => createAuth(db),
  inject: [DATABASE],
};

@Controller('api/auth')
export class AuthController {
  private readonly handler: ReturnType<typeof toNodeHandler>;

  constructor(@Inject(AUTH) auth: Auth) {
    this.handler = toNodeHandler(auth);
  }

  @All('*splat')
  async handle(@Req() req: Request, @Res() res: Response): Promise<void> {
    await this.handler(req, res);
  }
}

@Module({
  imports: [DatabaseModule],
  controllers: [AuthController],
  providers: [authProvider],
  exports: [AUTH],
})
export class AuthModule {}
