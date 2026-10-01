/**
 * The server `exports` module's request-and-serve service (ARCHITECTURE.md,
 * ADR-0008, ADR-0011). A request records one Export and enqueues exactly one
 * job; a status read returns the Export's current state; a succeeded Export's
 * artifact is fetched from the content-addressed store. Every path is scoped to
 * a Membership in the Export's Project, so an Export is never disclosed to a
 * non-Member.
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
import { membership, type Export } from '../db/schema.js';
import {
  EXPORT_ARTIFACT_STORAGE,
  type ExportArtifactStorage,
} from './export-artifact.storage.js';
import { ExportsQueue } from './exports.queue.js';
import { ExportsStore } from './exports.store.js';

@Injectable()
export class ExportsService {
  constructor(
    @Inject(DATABASE) private readonly db: NodePgDatabase,
    private readonly exports: ExportsStore,
    private readonly queue: ExportsQueue,
    @Inject(EXPORT_ARTIFACT_STORAGE)
    private readonly artifacts: ExportArtifactStorage,
  ) {}

  /**
   * Records one Export for a Member of `projectId` and enqueues exactly one job
   * carrying its id and requested format. The Project's Members are checked
   * first, so a caller with no Membership is refused with 403 before any record
   * is written or any job is enqueued.
   */
  async request(
    personId: string,
    projectId: string,
    format: string,
  ): Promise<Export> {
    await this.assertMember(personId, projectId, 'request an export');
    const created = await this.exports.create({ projectId, format });
    await this.queue.enqueue({ exportId: created.id, format: created.format });
    return created;
  }

  /**
   * Returns the Export's current record to a Member of its Project. A missing
   * id is refused with 404; a caller with no Membership is refused with 403
   * before the record is disclosed.
   */
  async get(personId: string, exportId: string): Promise<Export> {
    const found = await this.load(exportId);
    await this.assertMember(personId, found.projectId, 'read an export');
    return found;
  }

  /**
   * Returns the stored artifact bytes of a `succeeded` Export to a Member of
   * its Project. A missing id, an Export that has not produced an artifact, or
   * an artifact whose key names no stored bytes is refused with 404; a caller
   * with no Membership is refused with 403.
   */
  async getArtifact(personId: string, exportId: string): Promise<Uint8Array> {
    const found = await this.load(exportId);
    await this.assertMember(
      personId,
      found.projectId,
      'download an export artifact',
    );

    const absent = `Export ${exportId} has no artifact`;
    if (found.state !== 'succeeded' || found.storageKey === null) {
      throw new NotFoundException(absent);
    }

    const bytes = await this.artifacts.fetch(found.storageKey);
    if (bytes === null) {
      throw new NotFoundException(absent);
    }
    return bytes;
  }

  private async load(exportId: string): Promise<Export> {
    const found = await this.exports.findById(exportId);
    if (found === null) {
      throw new NotFoundException(`Export ${exportId} does not exist`);
    }
    return found;
  }

  private async assertMember(
    personId: string,
    projectId: string,
    action: string,
  ): Promise<void> {
    const [member] = await this.db
      .select({ id: membership.id })
      .from(membership)
      .where(
        and(
          eq(membership.personId, personId),
          eq(membership.projectId, projectId),
        ),
      )
      .limit(1);
    if (member === undefined) {
      throw new ForbiddenException(
        `only a Member of the Project may ${action}`,
      );
    }
  }
}
