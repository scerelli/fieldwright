import 'dart:async';
import 'dart:math' as math;

import '../features/visits/detection.dart';
import '../features/visits/determination.dart';
import '../features/visits/evidence.dart';
import '../features/visits/measurement.dart';
import '../features/visits/visit.dart';
import '../protocol/protocol.dart';
import '../store/config_dao.dart';
import '../store/detection_dao.dart';
import '../store/determination_dao.dart';
import '../store/evidence_dao.dart';
import '../store/measurement_dao.dart';
import '../store/outbox_dao.dart';
import '../store/site_dao.dart';
import '../store/visit_dao.dart';
import 'sync_client.dart';

/// The delivery state of a submitted Visit held in the client outbox.
///
/// A Visit is never dropped when the network is absent; only its delivery
/// waits, so the state follows the submission from [queued] through [syncing]
/// and [synced], or [failed] when a delivery attempt is rejected (UX-007).
enum SyncState { queued, syncing, synced, failed }

/// How the outbox retries a submission that could not reach the server
/// (UX-013). Each retry waits [initialBackoff] multiplied by [multiplier] once
/// per prior attempt — a bounded exponential backoff — up to [maxAttempts]
/// attempts, after which the Visit is left [SyncState.failed] and retryable.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialBackoff = const Duration(seconds: 2),
    this.multiplier = 2,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be at least 1');

  final int maxAttempts;
  final Duration initialBackoff;
  final double multiplier;

  /// The delay before retry number [attempt] (0-based).
  Duration backoffFor(int attempt) => Duration(
    microseconds:
        (initialBackoff.inMicroseconds * math.pow(multiplier, attempt)).round(),
  );
}

Future<void> _defaultSleep(Duration duration) => Future<void>.delayed(duration);

/// The client outbox: the queue of ended Visits awaiting delivery to the sync
/// API. Submitting writes to the local store, never to memory, so a Visit is
/// never lost when connectivity is absent or the app is killed — only its
/// delivery waits (UX-007, UX-013).
///
/// Delivery is idempotent on the Visit's client-generated UUIDv7 id: a retry or
/// re-upload sends the same id, so it never creates a second Visit
/// (ADR-0011). The transport, and the DAOs it writes through, are injected so
/// the outbox stays testable and its wiring is explicit.
class Outbox {
  Outbox(
    this._dao, {
    this._client,
    this._visits,
    this._sites,
    this._config,
    this._detections,
    this._determinations,
    this._evidence,
    this._measurements,
  });

  final OutboxDao _dao;
  final SyncClient? _client;
  final VisitDao? _visits;
  final SiteDao? _sites;

  /// The DAOs the submission aggregate is loaded from. Delivery needs the
  /// Visit's Detections, Determinations, Measurements and Evidence; [ConfigDao]
  /// additionally supplies the pinned Protocol version the INV-002 gate reads.
  /// They are optional so an outbox can be wired for queuing alone.
  final ConfigDao? _config;
  final DetectionDao? _detections;
  final DeterminationDao? _determinations;
  final EvidenceDao? _evidence;
  final MeasurementDao? _measurements;

  /// Queues [visit] for delivery. Only an ended Visit may be submitted
  /// (DOMAIN.md lifecycle); the submission is recorded as [SyncState.queued]
  /// and stays readable from the local store across a relaunch (UX-013). When
  /// the outbox is wired for delivery, queuing also kicks a flush so the Visit
  /// is delivered without the caller invoking the engine — the kick is
  /// non-blocking and swallows its own failure, so a dead network never throws
  /// at the caller or drops the Visit (UX-007).
  Future<void> submit(Visit visit) async {
    if (!visit.isEnded) {
      throw StateError('Only an ended Visit can be submitted');
    }
    await _dao.enqueue(visit.id);
    _kickDelivery();
  }

  /// Starts a flush in the background when the outbox can deliver. A failure is
  /// ignored here: the Visit stays queued/failed and is retried by the next
  /// kick or app start.
  void _kickDelivery() {
    if (_client == null || _visits == null || _sites == null) return;
    unawaited(flush().catchError((Object _) {}));
  }

  /// Loads each Detection's Determinations, pairing them with the Detection
  /// they belong to (DOMAIN.md › Determination) so the submission nests them
  /// correctly.
  Future<List<SubmittedDetection>> _withDeterminations(
    String visitId,
    List<Detection> detections,
  ) async {
    final determinations = _determinations;
    final entries = <SubmittedDetection>[];
    for (final detection in detections) {
      entries.add(
        SubmittedDetection(
          detection: detection,
          determinations: determinations == null
              ? const <Determination>[]
              : await determinations.forDetection(visitId, detection.taxonRef),
        ),
      );
    }
    return entries;
  }

  /// Delivers [visit] to the sync API and records the outcome. A delivered
  /// Visit becomes [SyncState.synced] and its lifecycle moves to `submitted`
  /// (DOMAIN.md). A rejection becomes [SyncState.failed] and stays retryable;
  /// a transient failure is retried with [retry]'s backoff first.
  Future<SyncState> deliver(
    Visit visit, {
    RetryPolicy retry = const RetryPolicy(),
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  }) async {
    final client = _client;
    final visits = _visits;
    final sites = _sites;
    if (client == null || visits == null || sites == null) {
      throw StateError('Outbox is not configured to deliver submissions');
    }
    if (visit.isInProgress) {
      throw StateError('Only an ended Visit can be delivered');
    }
    final site = await sites.findById(visit.siteId);
    if (site == null) {
      throw StateError(
        'Visit references a Site that is not in the local store',
      );
    }

    await _dao.enqueue(visit.id);

    final requiredEffortFields = await visits.requiredEffortFieldsFor(visit);
    if (requiredEffortFields.contains(SamplingEffortField.observers) &&
        visit.effort.observers.isEmpty) {
      // INV-005: a Visit whose Protocol version requires observers is not
      // delivered until they are recorded. Refuse it like a rejection — no
      // POST, never marked submitted — so it stays retryable once they are.
      await _dao.setSyncState(visit.id, SyncState.failed);
      return SyncState.failed;
    }

    final detections =
        await _detections?.forVisit(visit.id) ?? const <Detection>[];
    final aggregate = SubmissionAggregate(
      visit: visit,
      detections: await _withDeterminations(visit.id, detections),
      measurements:
          await _measurements?.forVisit(visit.id) ?? const <Measurement>[],
      evidence: await _evidence?.forVisit(visit.id) ?? const <Evidence>[],
    );

    // A Detection persisted before the client schema recorded methods carries a
    // null method, and a blank one would pass a validity check but is rejected
    // by the server just the same (`@IsNotEmpty`). The sync API's
    // `DetectionDto` requires a non-empty method, so refuse locally and leave
    // the Visit ended and retryable rather than POST a body the server would
    // reject as permanently undeliverable. New Detections always carry a method
    // — `DetectionDao.record` rejects a missing one (#318) — so this only
    // affects legacy rows.
    if (!allDetectionsHaveMethod(detections)) {
      await _dao.setSyncState(visit.id, SyncState.failed);
      return SyncState.failed;
    }

    // INV-002: a Visit cannot be submitted while any target taxon of its pinned
    // Protocol version has no Detection. Read the exact version the Visit
    // references — never the latest — and refuse locally, leaving the Visit
    // ended and retryable rather than marking it submitted. The server enforces
    // the same rule on its side.
    final config = _config;
    final protocolVersionId = visit.protocolVersionId;
    if (config != null && protocolVersionId != null) {
      final protocolVersion = await config.protocolVersion(protocolVersionId);
      final targets =
          protocolVersion?.document.targetList ?? const <TargetTaxon>[];
      if (!allTargetsRecorded(targets, detections)) {
        await _dao.setSyncState(visit.id, SyncState.failed);
        return SyncState.failed;
      }
    }

    final detectionMethods = await visits.detectionMethodsFor(visit.id);

    await _dao.setSyncState(visit.id, SyncState.syncing);
    var attempt = 0;
    while (true) {
      attempt += 1;
      try {
        final result = await client.submit(
          aggregate,
          projectId: site.projectId,
          requiredEffortFields: requiredEffortFields,
          detectionMethods: detectionMethods,
          submittedAt: (clock ?? DateTime.now)(),
        );
        if (result == SubmitResult.delivered) {
          await visits.markSubmitted(visit.id);
          await _dao.setSyncState(visit.id, SyncState.synced);
          return SyncState.synced;
        }
        await _dao.setSyncState(visit.id, SyncState.failed);
        return SyncState.failed;
      } on NotAuthenticated {
        // Not signed in yet: the Visit is valid and must not be failed or
        // retried with backoff. Park it as queued for the flush that runs once
        // the app is authenticated (UX-007).
        await _dao.setSyncState(visit.id, SyncState.queued);
        return SyncState.queued;
      } on SubmissionUnavailable {
        if (attempt >= retry.maxAttempts) {
          await _dao.setSyncState(visit.id, SyncState.failed);
          return SyncState.failed;
        }
        await (sleep ?? _defaultSleep)(retry.backoffFor(attempt - 1));
      }
    }
  }

  /// Delivers every queued or failed submission, oldest first. This is the
  /// entry point a caller invokes when connectivity returns (UX-007).
  ///
  /// Each Visit is delivered in isolation: one that cannot be delivered — a
  /// missing Site, an in-progress lifecycle, an unexpected store failure — is
  /// marked [SyncState.failed] and skipped, so an un-deliverable row ahead of
  /// the batch can never strand the Visits queued behind it (UX-013).
  Future<void> flush({
    RetryPolicy retry = const RetryPolicy(),
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  }) async {
    final visits = _visits;
    if (visits == null) {
      throw StateError('Outbox is not configured to deliver submissions');
    }
    for (final visitId in await _dao.pendingVisitIds()) {
      try {
        final visit = await visits.findById(visitId);
        if (visit == null) continue;
        await deliver(visit, retry: retry, clock: clock, sleep: sleep);
      } catch (_) {
        await _dao.setSyncState(visitId, SyncState.failed);
      }
    }
  }
}
