import type { Provider } from '@nestjs/common';
import { drizzle, type NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool, type QueryResult } from 'pg';

export const DATABASE_POOL = 'DATABASE_POOL';
export const DATABASE = 'DATABASE';
export const QUERY_EXECUTOR = 'QUERY_EXECUTOR';

export interface QueryExecutor {
  query(
    text: string,
    values?: unknown[],
  ): Promise<QueryResult<Record<string, unknown>>>;
}

export function createDatabasePool(databaseUrl: string | undefined): Pool {
  if (databaseUrl === undefined || databaseUrl === '') {
    throw new Error(
      'DATABASE_URL is not set: the database module needs a PostgreSQL connection string',
    );
  }

  return new Pool({ connectionString: databaseUrl });
}

export function createQueryExecutor(pool: Pool): QueryExecutor {
  return {
    query: (text, values) => pool.query<Record<string, unknown>>(text, values),
  };
}

export const databasePoolProvider: Provider = {
  provide: DATABASE_POOL,
  useFactory: () => createDatabasePool(process.env.DATABASE_URL),
};

export const queryExecutorProvider: Provider = {
  provide: QUERY_EXECUTOR,
  useFactory: (pool: Pool) => createQueryExecutor(pool),
  inject: [DATABASE_POOL],
};

export const databaseProvider: Provider = {
  provide: DATABASE,
  useFactory: (pool: Pool): NodePgDatabase => drizzle(pool),
  inject: [DATABASE_POOL],
};
