import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_client.dart';
import '../auth/auth_provider.dart';
import '../features/visits/detection.dart';
import '../features/visits/determination.dart';
import '../features/visits/evidence.dart';
import '../features/visits/measurement.dart';
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

/// One Detection of a [SubmissionAggregate] together with the Determinations
/// recorded against it, so the submission nests them under the Detection the
/// server's `SubmitVisitDto` expects.
class SubmittedDetection {
  const SubmittedDetection({
    required this.detection,
    this.determinations = const <Determination>[],
    this.provisional = false,
  });

  final Detection detection;
  final List<Determination> determinations;

  /// Whether this Detection's taxon is provisional — not yet resolved against
  /// the Project's pinned Taxonomic reference (GLOSSARY.md › Provisional taxon,
  /// INV-021). The submission carries it as `provisionalName` rather than a
  /// resolved `taxon` key, and the server stores it as it stands, provisional
  /// until an append-only Correction resolves it (ADR-0021).
  final bool provisional;
}

/// The whole Visit aggregate a submission carries (`DOMAIN.md` › Visit): the
/// Visit, its Detections with their Determinations, its Measurements with their
/// Provenance, and its Evidence. The outbox loads it from the local store and
/// [buildSubmitPayload] serializes it to the server's submit contract.
class SubmissionAggregate {
  const SubmissionAggregate({
    required this.visit,
    this.detections = const <SubmittedDetection>[],
    this.measurements = const <Measurement>[],
    this.evidence = const <Evidence>[],
  });

  final Visit visit;
  final List<SubmittedDetection> detections;
  final List<Measurement> measurements;
  final List<Evidence> evidence;
}

/// Builds the `POST /api/v1/visits` body for [aggregate], matching the server's
/// `SubmitVisitDto` (`ARCHITECTURE.md`'s sync compatibility surface).
///
/// `effort` carries a value under each Sampling-effort wire name the Visit's
/// Protocol version requires (INV-005): `start` is the recorded start,
/// `duration` the recorded end minus start in seconds, `observers` the recorded
/// observers, and `detectionMethods` the methods the Visit's Detections record.
/// The server only checks presence, never type; a field the version does not
/// require is omitted, so it can never be null where the server expects it.
///
/// Every Detection is serialized with its Determinations nested; every
/// Measurement carries its Provenance; the Evidence manifest carries only
/// Evidence that has been uploaded (a non-null [Evidence.storageKey]) and
/// references the Detection it belongs to by `detectionIndex`. The server
/// ignores unknown fields, so the shape stays additive-only (ADR-0011).
Map<String, dynamic> buildSubmitPayload(
  SubmissionAggregate aggregate, {
  required String projectId,
  List<SamplingEffortField> requiredEffortFields =
      const <SamplingEffortField>[],
  List<String> detectionMethods = const <String>[],
  DateTime? submittedAt,
}) {
  final visit = aggregate.visit;
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
  final detectionIndexByTaxon = <String, int>{
    for (var index = 0; index < aggregate.detections.length; index++)
      aggregate.detections[index].detection.taxonRef: index,
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
    'detections': <Map<String, dynamic>>[
      for (final entry in aggregate.detections)
        <String, dynamic>{
          // A Detection carries its resolved `taxon` key, or its explicit
          // `provisionalName` when the taxon has not resolved (INV-021,
          // GLOSSARY.md › Provisional taxon). The server stores either as it
          // stands, provisional until an append-only Correction resolves it
          // (ADR-0021), and the sync contract stays additive-only (ADR-0011).
          if (entry.provisional)
            'provisionalName': entry.detection.taxonRef
          else
            'taxon': entry.detection.taxonRef,
          'detected': entry.detection.detected,
          'method': entry.detection.method,
          if (entry.detection.count != null) 'count': entry.detection.count,
          if (entry.detection.opportunistic) 'opportunistic': true,
          if (entry.determinations.isNotEmpty)
            'determinations': _serializeDeterminations(entry.determinations),
        },
    ],
    'measurements': <Map<String, dynamic>>[
      for (final measurement in aggregate.measurements)
        <String, dynamic>{
          'value': measurement.value,
          // The server requires `unit` to be a string; a unitless covariate
          // submits an empty unit rather than a null the server would reject.
          'unit': measurement.unit ?? '',
          'provenance': measurement.provenance.toJson(),
        },
    ],
    'evidence': <Map<String, dynamic>>[
      for (final evidence in aggregate.evidence)
        if (evidence.storageKey != null)
          <String, dynamic>{
            if (detectionIndexByTaxon[evidence.taxonRef] != null)
              'detectionIndex': detectionIndexByTaxon[evidence.taxonRef]!,
            'kind': evidence.kind.name,
            'storageKey': evidence.storageKey!,
            'sha256': evidence.contentHash,
          },
    ],
  };
}

/// Serializes [determinations] for one Detection in the order the server needs:
/// a replaced Determination before its revision. Each revision then carries
/// `replacesIndex`, its position in this array, so the server resolves it to the
/// stored Determination's id and the append-only chain survives the submission
/// (INV-009). A `replacesId` naming no Determination in the array emits no
/// index rather than a dangling one the server would reject.
List<Map<String, dynamic>> _serializeDeterminations(
  List<Determination> determinations,
) {
  final ordered = _inRevisionOrder(determinations);
  final indexById = <String, int>{
    for (var index = 0; index < ordered.length; index++)
      ordered[index].id: index,
  };
  return <Map<String, dynamic>>[
    for (final determination in ordered)
      <String, dynamic>{
        'taxon': determination.taxon,
        if (determination.qualifier != null)
          'qualifier': determination.qualifier!.wireValue,
        if (determination.specimenCode != null)
          'specimenCode': determination.specimenCode,
        'determiner': determination.determiner,
        'date': determination.date.toUtc().toIso8601String(),
        if (determination.replacesId != null &&
            indexById.containsKey(determination.replacesId))
          'replacesIndex': indexById[determination.replacesId],
      },
  ];
}

/// Orders [determinations] so each one that replaces another follows it,
/// preserving the input order otherwise. Append-only storage already appends a
/// revision after its predecessor; this makes the invariant hold for any input
/// order, so [buildSubmitPayload] never emits a forward or dangling index. A
/// cycle — which append-only storage cannot produce — is broken by input order
/// so serialization always terminates.
List<Determination> _inRevisionOrder(List<Determination> determinations) {
  final byId = <String, Determination>{
    for (final determination in determinations) determination.id: determination,
  };
  final ordered = <Determination>[];
  final placed = <String>{};
  final visiting = <String>{};
  void place(Determination determination) {
    if (placed.contains(determination.id) ||
        visiting.contains(determination.id)) {
      return;
    }
    visiting.add(determination.id);
    final replacedId = determination.replacesId;
    final replaced = replacedId == null ? null : byId[replacedId];
    if (replaced != null) place(replaced);
    visiting.remove(determination.id);
    if (placed.add(determination.id)) ordered.add(determination);
  }

  for (final determination in determinations) {
    place(determination);
  }
  return ordered;
}

/// The client side of the versioned sync API's Visit submission
/// (`ARCHITECTURE.md`, ADR-0011): `POST /api/v1/visits` over the pinned dio
/// client (`TECH_STACK.md`).
///
/// The client-generated UUIDv7 `id` is the idempotency key, so a retry or a
/// re-upload of the same Visit never creates a second Visit on the server. A
/// response in the 4xx range is a rejection; a 5xx response, a timeout, or a
/// lost connection is retryable and raises [SubmissionUnavailable].
class SyncClient {
  SyncClient({required String baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  static const String submitPath = '/api/v1/visits';

  /// Submits the full [aggregate] to the sync API under [projectId].
  /// [requiredEffortFields] and [detectionMethods] are the Visit's
  /// Protocol-version requirements and its recorded Detection methods, carried
  /// into the payload's `effort`. `submittedAt` defaults to now; it is a
  /// parameter so a test can pin the timestamp.
  Future<SubmitResult> submit(
    SubmissionAggregate aggregate, {
    required String projectId,
    List<SamplingEffortField> requiredEffortFields =
        const <SamplingEffortField>[],
    List<String> detectionMethods = const <String>[],
    DateTime? submittedAt,
  }) async {
    final payload = buildSubmitPayload(
      aggregate,
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
