/**
 * The server `survey-periods` module's SurveyPeriod entity (ARCHITECTURE.md,
 * DOMAIN.md). A Survey period is a project-scoped entity inside Project: a
 * named date range in which Visits are expected. A Project's creator defines
 * it; the range is validated so an end date never precedes its start date, and
 * the Survey period belongs to exactly one Project.
 */
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { and, eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DATABASE } from '../db/database.provider.js';
import { membership, surveyPeriod, type SurveyPeriod } from '../db/schema.js';

export interface CreateSurveyPeriodInput {
  projectId: string;
  name: string;
  startDate: string;
  endDate: string;
}

@Injectable()
export class SurveyPeriodsService {
  constructor(@Inject(DATABASE) private readonly db: NodePgDatabase) {}

  /**
   * Creates a Survey period for a Project. Only the Project's creator may
   * define one; anyone else is rejected with 403. An end date preceding the
   * start date is rejected with 400 before anything is stored.
   */
  async create(
    personId: string,
    input: CreateSurveyPeriodInput,
  ): Promise<SurveyPeriod> {
    await this.assertCreator(personId, input.projectId);

    if (input.endDate < input.startDate) {
      throw new BadRequestException(
        'survey period end date precedes its start date',
      );
    }

    const [created] = await this.db
      .insert(surveyPeriod)
      .values({
        projectId: input.projectId,
        name: input.name,
        startDate: input.startDate,
        endDate: input.endDate,
      })
      .returning();

    return created;
  }

  /**
   * Lists a Project's Survey periods for any member of it. A non-member is
   * rejected with 404 so another Project's schedule is never disclosed.
   */
  async list(personId: string, projectId: string): Promise<SurveyPeriod[]> {
    await this.assertProjectAccess(personId, projectId);

    return this.db
      .select()
      .from(surveyPeriod)
      .where(eq(surveyPeriod.projectId, projectId));
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
      throw new ForbiddenException(
        'only the project creator can define survey periods',
      );
    }
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
