/**
 * The server `projects` module's Project aggregate (ARCHITECTURE.md). Creates a
 * Project with its settings and, in the same transaction, the creator's
 * Membership so a Project never exists without its creator.
 */
import {
  BadRequestException,
  ConflictException,
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
  description?: string;
  validationEnabled?: boolean;
  sensitiveTaxaObfuscation?: boolean;
  taxonomicReferenceId?: string;
  taxonomicReferenceVersion?: string;
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

/**
 * A Membership as the roster endpoint returns it: the stored Membership plus
 * the person's email, which references an external person identity and so is
 * not a column of `membership` itself.
 */
export interface ProjectMember extends Membership {
  email: string;
}

@Injectable()
export class ProjectsService {
  constructor(@Inject(DATABASE) private readonly db: NodePgDatabase) {}

  async create(personId: string, input: CreateProjectInput): Promise<Project> {
    const hasReferenceId = input.taxonomicReferenceId !== undefined;
    const hasReferenceVersion = input.taxonomicReferenceVersion !== undefined;
    if (hasReferenceId !== hasReferenceVersion) {
      throw new BadRequestException(
        'taxonomicReferenceId and taxonomicReferenceVersion must be provided together',
      );
    }

    return this.db.transaction(async (tx) => {
      const [created] = await tx
        .insert(project)
        .values({
          name: input.name,
          description: input.description ?? null,
          settings: {
            validationEnabled: input.validationEnabled ?? false,
            sensitiveTaxaObfuscation: input.sensitiveTaxaObfuscation ?? true,
          },
          taxonomicReferenceId: input.taxonomicReferenceId ?? null,
          taxonomicReferenceVersion: input.taxonomicReferenceVersion ?? null,
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
   * member or not, is rejected with 403. An email with no person is 404. A
   * person who is already a member is rejected with 409 (INV-014: at most one
   * Membership per person per Project).
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
      .onConflictDoNothing({
        target: [membership.personId, membership.projectId],
      })
      .returning();

    if (created === undefined) {
      throw new ConflictException('person is already a member');
    }

    return created;
  }

  /**
   * Lists a Project's Memberships to a member of that Project. Anyone who is
   * not a member is rejected with 403, so the roster is never shown to an
   * outsider. The person's email travels with each Membership for display.
   */
  async listMembers(
    personId: string,
    projectId: string,
  ): Promise<ProjectMember[]> {
    await this.assertMember(personId, projectId);

    return this.db
      .select({
        id: membership.id,
        personId: membership.personId,
        projectId: membership.projectId,
        role: membership.role,
        email: user.email,
      })
      .from(membership)
      .innerJoin(user, eq(user.id, membership.personId))
      .where(eq(membership.projectId, projectId));
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

  private async assertMember(
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
        ),
      )
      .limit(1);

    if (row === undefined) {
      throw new ForbiddenException('only project members can list members');
    }
  }
}
