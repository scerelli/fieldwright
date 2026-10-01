/**
 * The server `sync` module's versioned config pull (ARCHITECTURE.md,
 * ADR-0011): reads the Project configuration a device may be missing, keyed on
 * the opaque `versionToken` the previous pull returned. The token advances
 * whenever a Protocol version, Survey period or Site is created, so a pull
 * carrying the token from the immediately preceding pull is empty.
 *
 * The token is derived rather than stored: it is the greatest `created_at`
 * (epoch microseconds) across the Project's Protocol versions, Survey periods
 * and Sites. The sync module owns no aggregate (ARCHITECTURE.md); it only
 * reads the ones the projects and sites modules own, so no write path is added.
 */
import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  and,
  desc,
  eq,
  getTableColumns,
  gt,
  sql,
  type SQL,
} from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { PgColumn } from 'drizzle-orm/pg-core';
import { DATABASE } from '../db/database.provider.js';
import {
  membership,
  project,
  protocolVersion,
  site,
  surveyPeriod,
  type Project,
  type ProtocolVersion,
  type Site,
  type SurveyPeriod,
} from '../db/schema.js';

/** Epoch microseconds of a `timestamp` column, exact enough to key a token. */
function createdMicros(column: PgColumn): SQL<number> {
  return sql<number>`(floor(extract(epoch from ${column}) * 1000000))::double precision`;
}

/** Parses an opaque version token; anything unusable means a full pull. */
function parseSince(since: string | undefined): number | null {
  if (since === undefined || since === '') {
    return null;
  }
  if (!/^\d+$/.test(since)) {
    return null;
  }
  const value = Number(since);
  return Number.isSafeInteger(value) ? value : null;
}

/**
 * The changed configuration a pull returns. `project` is present only on a
 * full pull (no token), because Project settings have no mutation path and so
 * never change after creation; `protocolVersion` carries the Target list in
 * its document and is present only when it changed. `surveyPeriods` and
 * `sites` are always arrays, empty when nothing changed.
 */
export interface ConfigPull {
  versionToken: string;
  project?: Project;
  protocolVersion?: ProtocolVersion;
  surveyPeriods: SurveyPeriod[];
  sites: Site[];
}

@Injectable()
export class ConfigService {
  constructor(@Inject(DATABASE) private readonly db: NodePgDatabase) {}

  async pull(
    personId: string,
    projectId: string,
    since?: string,
  ): Promise<ConfigPull> {
    await this.assertMember(personId, projectId);

    const sinceMicros = parseSince(since);
    const [projectRow] = await this.db
      .select()
      .from(project)
      .where(eq(project.id, projectId))
      .limit(1);

    const protocol = await this.latestProtocolVersion(projectId, sinceMicros);
    const periods = await this.changedSurveyPeriods(projectId, sinceMicros);
    const sites = await this.changedSites(projectId, sinceMicros);
    const maxMicros = await this.latestChangeMicros(projectId);

    const pull: ConfigPull = {
      versionToken: String(Math.max(maxMicros, sinceMicros ?? 0)),
      surveyPeriods: periods,
      sites,
    };

    if (sinceMicros === null) {
      pull.project = projectRow;
    }
    if (protocol !== undefined) {
      pull.protocolVersion = protocol;
    }

    return pull;
  }

  /**
   * The Project's latest Protocol version, when it was created after the
   * token (or on a full pull). Its `document` carries the Target list.
   */
  private async latestProtocolVersion(
    projectId: string,
    sinceMicros: number | null,
  ): Promise<ProtocolVersion | undefined> {
    const [row] = await this.db
      .select({
        ...getTableColumns(protocolVersion),
        changeMicros: createdMicros(protocolVersion.createdAt),
      })
      .from(protocolVersion)
      .where(eq(protocolVersion.projectId, projectId))
      .orderBy(desc(protocolVersion.createdAt), desc(protocolVersion.version))
      .limit(1);

    if (row === undefined) {
      return undefined;
    }
    if (sinceMicros !== null && row.changeMicros <= sinceMicros) {
      return undefined;
    }

    const { changeMicros: _changeMicros, ...latest } = row;
    return latest;
  }

  private async changedSurveyPeriods(
    projectId: string,
    sinceMicros: number | null,
  ): Promise<SurveyPeriod[]> {
    const changed =
      sinceMicros === null
        ? eq(surveyPeriod.projectId, projectId)
        : and(
            eq(surveyPeriod.projectId, projectId),
            gt(createdMicros(surveyPeriod.createdAt), sinceMicros),
          );

    return this.db.select().from(surveyPeriod).where(changed);
  }

  private async changedSites(
    projectId: string,
    sinceMicros: number | null,
  ): Promise<Site[]> {
    const changed =
      sinceMicros === null
        ? eq(site.projectId, projectId)
        : and(
            eq(site.projectId, projectId),
            gt(createdMicros(site.createdAt), sinceMicros),
          );

    return this.db.select().from(site).where(changed);
  }

  /** The greatest `created_at` across the rows that advance the token. */
  private async latestChangeMicros(projectId: string): Promise<number> {
    const [protocol] = await this.db
      .select({
        max: sql<number | null>`max(${createdMicros(protocolVersion.createdAt)})`,
      })
      .from(protocolVersion)
      .where(eq(protocolVersion.projectId, projectId));
    const [period] = await this.db
      .select({
        max: sql<number | null>`max(${createdMicros(surveyPeriod.createdAt)})`,
      })
      .from(surveyPeriod)
      .where(eq(surveyPeriod.projectId, projectId));
    const [siteRow] = await this.db
      .select({
        max: sql<number | null>`max(${createdMicros(site.createdAt)})`,
      })
      .from(site)
      .where(eq(site.projectId, projectId));

    return Math.max(protocol?.max ?? 0, period?.max ?? 0, siteRow?.max ?? 0);
  }

  /**
   * A pull is scoped to Projects the current person is a Member of. A
   * non-member is rejected with 404, matching the other Project-scoped reads
   * so another Project's existence is never disclosed.
   */
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
      throw new NotFoundException('project not found');
    }
  }
}
