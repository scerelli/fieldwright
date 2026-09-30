import '../features/visits/visit.dart';
import '../store/outbox_dao.dart';

/// The delivery state of a submitted Visit held in the client outbox.
///
/// A Visit is never dropped when the network is absent; only its delivery
/// waits, so the state follows the submission from [queued] through [syncing]
/// and [synced], or [failed] when a delivery attempt is rejected (UX-007).
enum SyncState { queued, syncing, synced, failed }

/// The client outbox: the queue of ended Visits awaiting delivery to the sync
/// API. Submitting writes to the local store, never to memory, so a Visit is
/// never lost when connectivity is absent or the app is killed — only its
/// delivery waits (UX-007, UX-013).
class Outbox {
  Outbox(this._dao);

  final OutboxDao _dao;

  /// Queues [visit] for delivery. Only an ended Visit may be submitted
  /// (DOMAIN.md lifecycle); the submission is recorded as [SyncState.queued]
  /// and stays readable from the local store across a relaunch (UX-013).
  Future<void> submit(Visit visit) async {
    if (!visit.isEnded) {
      throw StateError('Only an ended Visit can be submitted');
    }
    await _dao.enqueue(visit.id);
  }
}
