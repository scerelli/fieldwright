/**
 * The server `exports` module's persistence (ARCHITECTURE.md). An Export is a
 * durable record of one requested export of a Project's data: the Project, the
 * requested format, its lifecycle state, the artifact's storage key once
 * produced, and the failure reason when its job fails. It is not a DOMAIN.md
 * aggregate, so this store only persists and reloads records; queueing,
 * serving and generation are the module's other layers.
 */
import { Inject, Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import { exportRecord, type Export, type ExportState } from '../db/schema.js';

/**
 * A request to persist an Export record. `state` defaults to `requested` at the
 * database; `storageKey` is absent until the job produces an artifact and
 * `error` is absent until a job fails.
 */
export interface CreateExportInput {
  projectId: string;
  format: string;
  state?: ExportState;
  storageKey?: string | null;
  error?: string | null;
}

@Injectable()
export class ExportsStore {
  constructor(@Inject(DATABASE) private readonly db: NodePgDatabase) {}

  async create(input: CreateExportInput): Promise<Export> {
    const [created] = await this.db
      .insert(exportRecord)
      .values({
        projectId: input.projectId,
        format: input.format,
        ...(input.state === undefined ? {} : { state: input.state }),
        storageKey: input.storageKey ?? null,
        error: input.error ?? null,
      })
      .returning();
    return created!;
  }

  async findById(id: string): Promise<Export | null> {
    const [found] = await this.db
      .select()
      .from(exportRecord)
      .where(eq(exportRecord.id, id))
      .limit(1);
    return found ?? null;
  }
}
