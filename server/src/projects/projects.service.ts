/**
 * The server `projects` module's Project aggregate (ARCHITECTURE.md). Creates a
 * Project with its settings and, in the same transaction, the creator's
 * Membership so a Project never exists without its creator.
 */
import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { and, eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import {
  membership,
  project,
  user,
  type Membership,
  type Project,
} from '../db/schema.js';

export interface CreateProjectInput {
  name: string;
  validationEnabled: boolean;
  sensitiveTaxaObfuscation: boolean;
  taxonomicReferenceId: string;
  taxonomicReferenceVersion: string;
}

/**
 * The roles this endpoint may grant. The `creator` role is deliberately
 * excluded: it is assigned by Project creation, never granted afterwards, so
 * only collector and validator are grantable.
 */
export type GrantableRole = 'collector' | 'validator';

export interface AddMemberInput {
  email: string;
  role: GrantableRole;
}

@Injectable()
export class ProjectsService {
  constructor(@Inject(DATABASE) private readonly db: NodePgDatabase) {}

  async create(personId: string, input: CreateProjectInput): Promise<Project> {
    return this.db.transaction(async (tx) => {
      const [created] = await tx
        .insert(project)
        .values({
          name: input.name,
          settings: {
            validationEnabled: input.validationEnabled,
            sensitiveTaxaObfuscation: input.sensitiveTaxaObfuscation,
          },
          taxonomicReferenceId: input.taxonomicReferenceId,
          taxonomicReferenceVersion: input.taxonomicReferenceVersion,
        })
        .returning();

      await tx.insert(membership).values({
        personId,
        projectId: created.id,
        role: 'creator',
      });

      return created;
    });
  }

  /**
   * Adds an existing person, resolved by email, to a Project as a collector or
   * validator. Only the Project's creator may grant roles: anyone else,
   * member or not, is rejected with 403. An email with no person is 404.
   */
  async addMember(
    personId: string,
    projectId: string,
    input: AddMemberInput,
  ): Promise<Membership> {
    await this.assertCreator(personId, projectId);

    const [target] = await this.db
      .select({ id: user.id })
      .from(user)
      .where(eq(user.email, input.email))
      .limit(1);

    if (target === undefined) {
      throw new NotFoundException('person not found');
    }

    const [created] = await this.db
      .insert(membership)
      .values({
        personId: target.id,
        projectId,
        role: input.role,
      })
      .returning();

    return created;
  }

  private async assertCreator(
    personId: string,
    projectId: string,
  ): Promise<void> {
    const [row] = await this.db
      .select({ id: membership.id })
      .from(membership)
      .where(
        and(
          eq(membership.personId, personId),
          eq(membership.projectId, projectId),
          eq(membership.role, 'creator'),
        ),
      )
      .limit(1);

    if (row === undefined) {
      throw new ForbiddenException('only the project creator can add members');
    }
  }
}
