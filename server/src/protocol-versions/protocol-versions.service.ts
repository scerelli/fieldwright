/**
 * The server `protocol-versions` module's ProtocolVersion entity
 * (ARCHITECTURE.md, DOMAIN.md). A Protocol version is a project-scoped,
 * append-only snapshot of a Protocol: the document is validated against the
 * shared packages/protocol JSON Schema (ADR-0009) and given a server-assigned
 * monotonic version number. Freezing is the point at which a Visit first
 * references the version (INV-007): a frozen version is never updated, and a
 * change creates a new version.
 */
import { readFileSync } from 'node:fs';
import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Ajv2020, type ValidateFunction } from 'ajv/dist/2020.js';
import { and, eq, max } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import {
  membership,
  protocolVersion,
  type ProtocolVersion,
} from '../db/schema.js';

const protocolSchema = JSON.parse(
  readFileSync(
    new URL(
      '../../../packages/protocol/schema/protocol.schema.json',
      import.meta.url,
    ),
    'utf8',
  ),
) as object;

const validateProtocolDocument: ValidateFunction = new Ajv2020({
  allErrors: true,
  strict: true,
}).compile(protocolSchema);

export interface CreateProtocolVersionInput {
  projectId: string;
  document: Record<string, unknown>;
}

@Injectable()
export class ProtocolVersionsService {
  constructor(@Inject(DATABASE) private readonly db: NodePgDatabase) {}

  async create(
    personId: string,
    input: CreateProtocolVersionInput,
  ): Promise<ProtocolVersion> {
    await this.assertProjectAccess(personId, input.projectId);

    const { protocolId } = input.document;
    if (typeof protocolId !== 'string' || protocolId.length === 0) {
      throw new BadRequestException(
        'protocol document must carry a protocolId',
      );
    }

    return this.db.transaction(async (tx) => {
      const [current] = await tx
        .select({ version: max(protocolVersion.version) })
        .from(protocolVersion)
        .where(
          and(
            eq(protocolVersion.projectId, input.projectId),
            eq(protocolVersion.protocolId, protocolId),
          ),
        );

      const version = (current?.version ?? 0) + 1;
      const document = { ...input.document, version };
      if (!validateProtocolDocument(document)) {
        throw new BadRequestException({
          message: 'protocol document does not match the protocol schema',
          errors: validateProtocolDocument.errors,
        });
      }

      const [created] = await tx
        .insert(protocolVersion)
        .values({
          projectId: input.projectId,
          protocolId,
          version,
          document,
        })
        .returning();

      return created;
    });
  }

  async freeze(personId: string, id: string): Promise<ProtocolVersion> {
    const existing = await this.findById(id);
    if (existing === undefined) {
      throw new NotFoundException('protocol version not found');
    }
    await this.assertProjectAccess(personId, existing.projectId);

    if (existing.frozenAt !== null) {
      return existing;
    }

    const [frozen] = await this.db
      .update(protocolVersion)
      .set({ frozenAt: new Date() })
      .where(eq(protocolVersion.id, id))
      .returning();

    return frozen;
  }

  private async findById(id: string): Promise<ProtocolVersion | undefined> {
    const [row] = await this.db
      .select()
      .from(protocolVersion)
      .where(eq(protocolVersion.id, id))
      .limit(1);
    return row;
  }

  private async assertProjectAccess(
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
      throw new NotFoundException('project not found');
    }
  }
}
