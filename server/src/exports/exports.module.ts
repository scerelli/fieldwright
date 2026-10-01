/**
 * The server `exports` module (ARCHITECTURE.md): the durable Export records and,
 * in later sub-tasks, the request/serve API, the BullMQ queue and the artifact
 * storage and generators. For now it scaffolds the module around its
 * persistence so a requested export has a state from request to artifact.
 */
import { Module } from '@nestjs/common';
import { DatabaseModule } from '../db/database.module.js';
import { ExportsStore } from './exports.store.js';

@Module({
  imports: [DatabaseModule],
  providers: [ExportsStore],
  exports: [ExportsStore],
})
export class ExportsModule {}
