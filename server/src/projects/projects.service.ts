/**
 * The server `projects` module's Project aggregate (ARCHITECTURE.md). Creates a
 * Project with its settings and, in the same transaction, the creator's
 * Membership so a Project never exists without its creator.
 */
import { Inject, Injectable } from '@nestjs/common';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import { membership, project, type Project } from '../db/schema.js';

export interface CreateProjectInput {
  name: string;
  validationEnabled: boolean;
  sensitiveTaxaObfuscation: boolean;
  taxonomicReferenceId: string;
  taxonomicReferenceVersion: string;
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
}
