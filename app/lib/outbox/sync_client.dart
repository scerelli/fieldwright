import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_client.dart';
import '../auth/auth_provider.dart';
import '../features/visits/visit.dart';
import '../protocol/protocol.dart';

/// The outcome of one submission attempt to the sync API.
enum SubmitResult {
  /// The server accepted the Visit. A replay of the same id resolves to the
  /// Visit already stored under it, so it is delivered without a second row
  /// (ADR-0011).
  delivered,

  /// The server refused the Visit. The outbox keeps it as a retryable failure.
  rejected,
}

/// Raised when a submission did not reach the server, or the server was
/// temporarily unable to handle it. The outbox retries it with backoff instead
/// of dropping it (UX-013).
class SubmissionUnavailable implements Exception {
  const SubmissionUnavailable(this.message);

  final String message;

  @override
  String toString() => 'SubmissionUnavailable: $message';
}

/// Raised when the sync API refuses a submission because the request is not
/// authenticated (HTTP 401/403). It is a [SubmissionUnavailable] — the Visit is
/// valid and retryable — but the outbox parks it as `queued` instead of
/// exhausting retries, because only signing in can unblock it (UX-007).
class NotAuthenticated extends SubmissionUnavailable {
  const NotAuthenticated(super.message);
}

/// The client side of the versioned sync API's Visit submission
/// (`ARCHITECTURE.md`, ADR-0011): `POST /api/v1/visits` over the pinned dio
/// client (`TECH_STACK.md`).
///
/// The client-generated UUIDv7 `id` is the idempotency key, so a retry or a
/// re-upload of the same Visit never creates a second Visit on the server. A
/// response in the 4xx range is a rejection; a 5xx response, a timeout, or a
/// lost connection is retryable and raises [SubmissionUnavailable].
/// The `POST /api/v1/visits` body for [visit] (`ARCHITECTURE.md`, ADR-0011).
///
/// `effort` carries a value under each Sampling-effort wire name the Visit's
/// Protocol version requires (INV-005): `start` is the recorded start,
/// `duration` the recorded end minus start in seconds, `observers` the recorded
/// observers, and `detectionMethods` the methods the Visit's Detections record.
/// The server only checks presence, never type; a field the version does not
/// require is omitted, so it can never be null where the server expects it.
Map<String, dynamic> buildSubmitPayload(
  Visit visit, {
  required String projectId,
  List<SamplingEffortField> requiredEffortFields =
      const <SamplingEffortField>[],
  List<String> detectionMethods = const <String>[],
  DateTime? submittedAt,
}) {
  final startedAt = visit.effort.startedAt.toUtc();
  final endedAt = visit.effort.endedAt?.toUtc();
  final required = requiredEffortFields.toSet();
  final effort = <String, dynamic>{
    if (required.contains(SamplingEffortField.start))
      'start': startedAt.toIso8601String(),
    if (required.contains(SamplingEffortField.duration))
      'duration': endedAt == null ? 0 : endedAt.difference(startedAt).inSeconds,
    if (required.contains(SamplingEffortField.observers))
      'observers': visit.effort.observers,
    if (required.contains(SamplingEffortField.detectionMethods))
      'detectionMethods': detectionMethods,
  };
  return <String, dynamic>{
    'id': visit.id,
    'projectId': projectId,
    'siteId': visit.siteId,
    'surveyPeriodId': visit.surveyPeriodId,
    'protocolVersionId': visit.protocolVersionId,
    'effort': effort,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'submittedAt': (submittedAt ?? DateTime.now()).toUtc().toIso8601String(),
  };
}

class SyncClient {
  SyncClient({required String baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  static const String submitPath = '/api/v1/visits';

  /// Submits [visit] to the sync API under [projectId]. [requiredEffortFields]
  /// and [detectionMethods] are the Visit's Protocol-version requirements and
  /// its recorded Detection methods, carried into the payload's `effort`.
  /// `submittedAt` defaults to now; it is a parameter so a test can pin the
  /// timestamp.
  Future<SubmitResult> submit(
    Visit visit, {
    required String projectId,
    List<SamplingEffortField> requiredEffortFields =
        const <SamplingEffortField>[],
    List<String> detectionMethods = const <String>[],
    DateTime? submittedAt,
  }) async {
    final payload = buildSubmitPayload(
      visit,
      projectId: projectId,
      requiredEffortFields: requiredEffortFields,
      detectionMethods: detectionMethods,
      submittedAt: submittedAt,
    );

    try {
      await _dio.post<void>(
        submitPath,
        data: payload,
        options: Options(headers: _auth.authHeaders),
      );
      return SubmitResult.delivered;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const NotAuthenticated('Not authenticated with the sync API');
      }
      if (status != null && status >= 400 && status < 500) {
        return SubmitResult.rejected;
      }
      throw SubmissionUnavailable(error.message ?? 'Submission failed');
    }
  }
}

/// The production [SyncClient]: the self-hosted server root with the current
/// sign-in attached, so the outbox can deliver without a caller wiring the
/// transport by hand (`ARCHITECTURE.md`'s sync compatibility surface).
final syncClientProvider = Provider<SyncClient>(
  (ref) =>
      SyncClient(baseUrl: authBaseUrl, auth: ref.watch(authClientProvider)),
);
