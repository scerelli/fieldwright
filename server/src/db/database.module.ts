import { Module } from '@nestjs/common';
import {
  DATABASE,
  DATABASE_POOL,
  QUERY_EXECUTOR,
  databasePoolProvider,
  databaseProvider,
  queryExecutorProvider,
} from './database.provider.js';

@Module({
  providers: [databasePoolProvider, databaseProvider, queryExecutorProvider],
  exports: [DATABASE_POOL, DATABASE, QUERY_EXECUTOR],
})
export class DatabaseModule {}
