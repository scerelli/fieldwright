import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_client.dart';
import '../auth/auth_provider.dart';
import '../features/visits/evidence.dart';
import '../store/evidence_dao.dart';

/// The server's stored-media reference: the content-addressed `storageKey` an
/// upload returns and the `sha256` of the stored bytes (`POST /api/v1/media`,
/// ADR-0012).
///
/// When the server is backed by a volume its `store` writes the bytes itself
/// and [uploadUrl] is absent. When an S3 backend is configured and the object
/// is not already stored, the server returns a presigned [uploadUrl] and the
/// [uploadHeaders] the client must send with its PUT of the exact bytes
/// (`ARCHITECTURE.md`, ADR-0012).
class StoredMedia {
  const StoredMedia({
    required this.storageKey,
    required this.sha256,
    this.uploadUrl,
    this.uploadHeaders,
  });

  factory StoredMedia.fromJson(Map<String, dynamic> json) {
    final storageKey = json['storageKey'];
    final sha256 = json['sha256'];
    final uploadUrl = json['uploadUrl'];
    final rawHeaders = json['uploadHeaders'];
    if (storageKey is! String || sha256 is! String) {
      throw const FormatException('Malformed media upload response');
    }
    if (uploadUrl != null && uploadUrl is! String) {
      throw const FormatException('Malformed media upload response');
    }
    Map<String, String>? uploadHeaders;
    if (rawHeaders != null) {
      if (rawHeaders is! Map) {
        throw const FormatException('Malformed media upload response');
      }
      uploadHeaders = <String, String>{};
      for (final entry in rawHeaders.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! String) {
          throw const FormatException('Malformed media upload response');
        }
        uploadHeaders[key] = value;
      }
    }
    return StoredMedia(
      storageKey: storageKey,
      sha256: sha256,
      uploadUrl: uploadUrl as String?,
      uploadHeaders: uploadHeaders,
    );
  }

  final String storageKey;
  final String sha256;

  /// The presigned PUT URL the client sends the bytes to, or `null` when the
  /// server already stored them.
  final String? uploadUrl;

  /// The headers the presigned PUT must carry, bound to the exact bytes; `null`
  /// when [uploadUrl] is absent.
  final Map<String, String>? uploadHeaders;
}

/// Raised when an Evidence upload did not reach the server, or the server was
/// temporarily unable to store it. The local file is untouched and the
/// Evidence carries no `storageKey`, so the upload is retryable and no data is
/// lost (UX-013).
class MediaUnavailable implements Exception {
  const MediaUnavailable(this.message);

  final String message;

  @override
  String toString() => 'MediaUnavailable: $message';
}

/// Raised when the media API refuses an upload because the request is not
/// authenticated (HTTP 401/403). It is a [MediaUnavailable] — the upload is
/// valid and retryable — but the caller parks it rather than exhausting
/// retries, because only signing in can unblock it (UX-007).
class MediaNotAuthenticated extends MediaUnavailable {
  const MediaNotAuthenticated(super.message);
}

/// Raised when the media API refuses an upload for a reason retrying cannot
/// fix (a non-auth 4xx, or a server-side hash that does not match the local
/// bytes). The Evidence keeps no `storageKey`, but the caller does not retry
/// (mirrors the sync client's `rejected`).
class MediaRejected implements Exception {
  const MediaRejected(this.message);

  final String message;

  @override
  String toString() => 'MediaRejected: $message';
}

/// The client side of the media API's Evidence upload (`ARCHITECTURE.md`,
/// ADR-0012): `POST /api/v1/media` sends the file's raw bytes
/// (`application/octet-stream`) over the pinned dio client (`TECH_STACK.md`).
///
/// The server either stores the bytes itself (volume backend) or answers with
/// a presigned [StoredMedia.uploadUrl]; when the latter is present this client
/// PUTs the same bytes to it with [StoredMedia.uploadHeaders] before it
/// reports success. The request carries the current sign-in's headers exactly
/// as the sync client's submission does.
///
/// The POST follows the sync client's classification: 401/403 raises
/// [MediaNotAuthenticated] (do not burn retries), another 4xx raises
/// [MediaRejected] (non-retryable), and a 5xx, lost connection, missing local
/// file, or malformed response raises the retryable [MediaUnavailable]. The
/// presigned PUT has its own classification: a 2xx or a 412 (already stored) is
/// success, and every other outcome is the retryable [MediaUnavailable].
/// Nothing is persisted on any failure.
class MediaClient {
  MediaClient({required String baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  static const String uploadPath = '/api/v1/media';

  /// Uploads the file at [filePath] and returns what the server stored. The
  /// body is the file's bytes, never multipart; the path is read fresh so a
  /// retry re-reads the same local file. When the response carries a presigned
  /// `uploadUrl`, the bytes are PUT there with the signed headers before this
  /// returns; a 2xx or a 412 (already stored under the content-addressed key)
  /// counts as stored, while any other PUT outcome raises [MediaUnavailable]
  /// and the caller must not treat the object as stored.
  Future<StoredMedia> uploadFile(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final response = await _dio.post<Map<String, dynamic>>(
        uploadPath,
        data: bytes,
        options: Options(
          headers: <String, String>{
            ..._auth.authHeaders,
            Headers.contentTypeHeader: 'application/octet-stream',
          },
        ),
      );
      final body = response.data;
      if (body == null) {
        throw const MediaUnavailable('Empty media upload response');
      }
      final stored = StoredMedia.fromJson(body);
      final uploadUrl = stored.uploadUrl;
      if (uploadUrl != null) {
        await _putPresigned(
          uploadUrl,
          bytes,
          stored.uploadHeaders ?? const <String, String>{},
        );
      }
      return stored;
    } on MediaUnavailable {
      rethrow;
    } on FormatException catch (error) {
      throw MediaUnavailable(error.message);
    } on FileSystemException catch (error) {
      throw MediaUnavailable(error.message);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  /// PUTs [bytes] to a presigned [uploadUrl]. A 2xx writes the object; a 412
  /// means it already exists under the content-addressed key (the
  /// `If-None-Match: *` conditional lost a race), which is equally success —
  /// the object the caller needs is already stored. Every other outcome is
  /// retryable [MediaUnavailable]: re-running the whole upload self-heals (the
  /// re-POST finds the object present and returns no `uploadUrl`), so a
  /// permanent classification would only add a silent-loss path.
  Future<void> _putPresigned(
    String uploadUrl,
    List<int> bytes,
    Map<String, String> headers,
  ) async {
    try {
      await _dio.put<void>(
        uploadUrl,
        data: bytes,
        options: Options(headers: headers),
      );
    } on DioException catch (error) {
      final failure = _putFailure(error);
      if (failure != null) {
        throw failure;
      }
    }
  }

  /// Uploads [evidence]'s local file and persists the returned `storageKey` on
  /// its row through [dao], returning the Evidence with the key filled in. The
  /// server's `sha256` must equal the Evidence's local `contentHash` — both are
  /// the hash of the same bytes — or the upload is rejected and nothing is
  /// persisted. When the upload fails nothing is persisted and the local file
  /// is kept, so the same Evidence can be uploaded again.
  Future<Evidence> uploadEvidence(Evidence evidence, EvidenceDao dao) async {
    final stored = await uploadFile(evidence.filePath);
    if (stored.sha256 != evidence.contentHash) {
      throw MediaRejected(
        'Server hash ${stored.sha256} does not match local content hash '
        '${evidence.contentHash}',
      );
    }
    await dao.markUploaded(evidence.id, stored.storageKey);
    return evidence.withStorageKey(stored.storageKey);
  }
}

/// Classifies a POST `/api/v1/media` failure. A 401/403 is an authentication
/// problem ([MediaNotAuthenticated], parked rather than retried); another 4xx
/// is a permanent rejection ([MediaRejected]); everything else is retryable.
Exception _failure(DioException error) {
  final status = error.response?.statusCode;
  if (status == 401 || status == 403) {
    return const MediaNotAuthenticated('Not authenticated with the media API');
  }
  if (status != null && status >= 400 && status < 500) {
    return MediaRejected('Media upload rejected with status $status');
  }
  return MediaUnavailable(error.message ?? 'Media upload failed');
}

/// Classifies a presigned PUT failure, whose semantics differ from the POST's.
/// Returns `null` when the outcome means success — a 412 precondition failure
/// is the object already stored at the content-addressed key — and a retryable
/// [MediaUnavailable] for every other outcome. Never [MediaNotAuthenticated]:
/// a PUT 403 is an expired or invalid signature, not a sign-in problem. Never
/// [MediaRejected]: retrying the whole upload is safe and self-healing.
Exception? _putFailure(DioException error) {
  if (error.response?.statusCode == 412) {
    return null;
  }
  return MediaUnavailable(error.message ?? 'Presigned media upload failed');
}

/// The production [MediaClient]: the self-hosted server root with the current
/// sign-in attached, so the outbox uploads Evidence without a caller wiring
/// the transport by hand (`ARCHITECTURE.md`'s media compatibility surface).
final mediaClientProvider = Provider<MediaClient>(
  (ref) =>
      MediaClient(baseUrl: authBaseUrl, auth: ref.watch(authClientProvider)),
);
