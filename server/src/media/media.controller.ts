/**
 * The server `media` module's auth-guarded REST surface (ARCHITECTURE.md,
 * ADR-0012). `POST /api/v1/media` accepts an Evidence file's bytes and stores
 * them through the storage abstraction, returning the `storageKey` and
 * `sha256` the Evidence manifest references; `GET /api/v1/media/:storageKey`
 * streams the stored file back. This endpoint writes the file only — the
 * Evidence record is persisted with the submitted Visit by the `visits`
 * module — and storage is content-addressed, so identical bytes store once
 * and a stored Evidence file is never mutated.
 */
import {
  Controller,
  Get,
  Inject,
  Param,
  PayloadTooLargeException,
  Post,
  Req,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { AuthGuard } from '../auth/auth.guard.js';
import { MEDIA_CONFIG, type MediaConfig } from './media.config.js';
import { MediaService } from './media.service.js';
import type { StoredMedia } from './media.storage.js';

@Controller('api/v1/media')
export class MediaController {
  constructor(
    private readonly media: MediaService,
    @Inject(MEDIA_CONFIG) private readonly config: MediaConfig,
  ) {}

  @UseGuards(AuthGuard)
  @Post()
  async upload(@Req() request: Request): Promise<StoredMedia> {
    const bytes = await readBytes(request, this.config.maxUploadBytes);
    return this.media.store(bytes);
  }

  /**
   * v1 access model: the route is authenticated and keyed by the unguessable
   * content-addressed `storageKey`, so possessing the key is the access.
   * Per-Project Membership/role scoping and stripping sensitive location
   * fields (e.g. GPS EXIF coordinates) are deliberately deferred and tracked as
   * a separate sensitive-data follow-up — the `media` module owns no aggregate,
   * so this route adds no Project scoping.
   */
  @UseGuards(AuthGuard)
  @Get(':storageKey')
  async download(
    @Param('storageKey') storageKey: string,
  ): Promise<StreamableFile> {
    const bytes = await this.media.fetch(storageKey);
    return new StreamableFile(Buffer.from(bytes), {
      type: 'application/octet-stream',
    });
  }
}

/**
 * Reads the request's raw body, rejecting anything over `limit` with a 413
 * before it can be buffered. The default body parser only consumes
 * `application/json` and form bodies, so an `application/octet-stream`
 * Evidence upload reaches this handler as an unread stream — and neither parser
 * bounds it. The declared `Content-Length` is checked up front (the common
 * case), and the running byte count is enforced while streaming so a request
 * that omits or understates its length still fails closed rather than growing
 * the buffer without bound.
 */
async function readBytes(request: Request, limit: number): Promise<Uint8Array> {
  const declared = request.headers['content-length'];
  if (declared !== undefined && Number(declared) > limit) {
    throw new PayloadTooLargeException();
  }

  const chunks: Buffer[] = [];
  let size = 0;
  for await (const chunk of request) {
    const buffer = Buffer.isBuffer(chunk)
      ? chunk
      : Buffer.from(chunk as Uint8Array);
    size += buffer.length;
    if (size > limit) {
      throw new PayloadTooLargeException();
    }
    chunks.push(buffer);
  }
  return Buffer.concat(chunks);
}
