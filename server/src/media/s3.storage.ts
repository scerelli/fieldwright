/**
 * The optional S3-compatible `MediaStorage` backend (ADR-0007, ADR-0012). A
 * stored file is still content-addressed by the lowercase-hex SHA-256 of its
 * bytes, so identical bytes resolve to the same key and an existing Evidence
 * object is never overwritten: when the object is already present this returns
 * its key without a presigned URL, so the client has nothing to re-upload. When
 * it is absent it returns a presigned `PutObject` URL and the client sends the
 * bytes directly to S3 (ADR-0012).
 */
import { createHash } from 'node:crypto';
import {
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import type { S3MediaConfig } from './media.config.js';
import type { MediaStorage, StoredMedia } from './media.storage.js';

/** A storage key is exactly the lowercase-hex SHA-256 of the stored bytes. */
const STORAGE_KEY_PATTERN = /^[0-9a-f]{64}$/;

export function createS3Storage(config: S3MediaConfig): MediaStorage {
  const client = new S3Client({
    region: config.region,
    ...(config.endpoint === undefined ? {} : { endpoint: config.endpoint }),
    forcePathStyle: config.forcePathStyle,
    credentials: {
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
    },
    // A presigned URL is PUT from outside the SDK, so the client cannot attach
    // the flexible-checksum headers the SDK would otherwise sign in; requesting
    // them only when S3 requires keeps a plain PUT acceptable (AWS guidance for
    // presigned uploads).
    requestChecksumCalculation: 'WHEN_REQUIRED',
    responseChecksumValidation: 'WHEN_REQUIRED',
  });

  return {
    async store(bytes: Uint8Array): Promise<StoredMedia> {
      const sha256 = createHash('sha256').update(bytes).digest('hex');

      if (await objectExists(client, config.bucket, sha256)) {
        return { storageKey: sha256, sha256 };
      }

      const uploadUrl = await getSignedUrl(
        client,
        new PutObjectCommand({ Bucket: config.bucket, Key: sha256 }),
        { expiresIn: config.presignExpirySeconds },
      );

      return { storageKey: sha256, sha256, uploadUrl };
    },

    async fetch(storageKey: string): Promise<Uint8Array | null> {
      if (!STORAGE_KEY_PATTERN.test(storageKey)) {
        return null;
      }

      try {
        const object = await client.send(
          new GetObjectCommand({ Bucket: config.bucket, Key: storageKey }),
        );
        if (object.Body === undefined) {
          return null;
        }
        return await object.Body.transformToByteArray();
      } catch (error) {
        if (isNotFound(error)) {
          return null;
        }
        throw error;
      }
    },
  };
}

async function objectExists(
  client: S3Client,
  bucket: string,
  key: string,
): Promise<boolean> {
  try {
    await client.send(new HeadObjectCommand({ Bucket: bucket, Key: key }));
    return true;
  } catch (error) {
    if (isNotFound(error)) {
      return false;
    }
    throw error;
  }
}

/**
 * A missing key is a 404 from S3; the SDK models it as `NoSuchKey`/`NotFound`
 * (and some S3-compatible services only set the HTTP status), so both are
 * treated as not-found.
 */
function isNotFound(error: unknown): boolean {
  if (typeof error !== 'object' || error === null) {
    return false;
  }
  const name = (error as { name?: unknown }).name;
  const status = (error as { $metadata?: { httpStatusCode?: number } })
    .$metadata?.httpStatusCode;
  return name === 'NoSuchKey' || name === 'NotFound' || status === 404;
}
