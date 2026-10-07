import 'dart:async';

import 'package:drift/drift.dart';

import '../outbox/outbox.dart';
import 'app_database.dart';

/// The aggregate sync state of every Visit in the outbox: how many are queued,
/// currently syncing, or failed. The shell reads this to report a single system
/// state without loading each Visit (UX-008).
class OutboxSummary {
  const OutboxSummary({this.queued = 0, this.syncing = 0, this.failed = 0});

  final int queued;
  final int syncing;
  final int failed;

  /// No Visit is awaiting delivery, in flight, or failed.
  static const OutboxSummary none = OutboxSummary();

  bool get hasQueued => queued > 0;
  bool get hasSyncing => syncing > 0;
  bool get hasFailed => failed > 0;
}

/// Reads and writes the client outbox: the queue of ended Visits awaiting
/// delivery, each carrying its [SyncState]. Rows live in the local store, so a
/// queued submission survives an app relaunch (UX-013).
class OutboxDao {
  OutboxDao(this._database);

  final AppDatabase _database;

  /// Emits the aggregate summary after every write, so the shell indicator
  /// follows a submission from in flight to failed without a caller
  /// invalidating a provider by hand (UX-008). A plain broadcast controller is
  /// used instead of a drift query stream so no query-cache eviction timer
  /// outlives a caller that does not close the database. It is deliberately
  /// never closed: the DAO lives for the container that owns it, and closing
  /// the shared controller on one subscriber's disposal would silence the rest.
  final StreamController<OutboxSummary> _changes =
      StreamController<OutboxSummary>.broadcast();

  /// The aggregate outbox state, re-emitted after each write ([enqueue],
  /// [setSyncState]).
  Stream<OutboxSummary> get changes => _changes.stream;

  /// Records [visitId] as awaiting delivery. Idempotent: a Visit already in
  /// the outbox keeps the state it has.
  Future<void> enqueue(String visitId, {DateTime? queuedAt}) async {
    await _database
        .into(_database.outboxEntries)
        .insert(
          OutboxEntriesCompanion.insert(
            visitId: visitId,
            syncState: SyncState.queued,
            queuedAt: (queuedAt ?? DateTime.now()).toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await _emitSummary();
  }

  /// The sync state recorded for [visitId], or `null` when the Visit is not in
  /// the outbox.
  Future<SyncState?> syncStateOf(String visitId) async {
    final row = await (_database.select(
      _database.outboxEntries,
    )..where((table) => table.visitId.equals(visitId))).getSingleOrNull();
    return row?.syncState;
  }

  /// The ids of the Visits still awaiting delivery — queued, failed, or left
  /// `syncing` by a crash mid-delivery — oldest first, so a flush after
  /// connectivity returns works through them in order and no Visit is stranded
  /// in a non-terminal state (UX-007, UX-013).
  Future<List<String>> pendingVisitIds() async {
    final rows =
        await (_database.select(_database.outboxEntries)
              ..where(
                (table) =>
                    table.syncState.equalsValue(SyncState.queued) |
                    table.syncState.equalsValue(SyncState.failed) |
                    table.syncState.equalsValue(SyncState.syncing),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.queuedAt)]))
            .get();
    return rows.map((row) => row.visitId).toList(growable: false);
  }

  /// The aggregate outbox state: how many Visits are queued, currently
  /// syncing, or failed, so the shell can report one system state without
  /// loading each Visit (UX-008).
  Future<OutboxSummary> summary() async {
    final count = _database.outboxEntries.visitId.count();
    final query = _database.selectOnly(_database.outboxEntries)
      ..addColumns([_database.outboxEntries.syncState, count])
      ..groupBy([_database.outboxEntries.syncState]);
    final rows = await query.get();
    var queued = 0;
    var syncing = 0;
    var failed = 0;
    for (final row in rows) {
      final state = row.readWithConverter(_database.outboxEntries.syncState);
      final n = row.read(count) ?? 0;
      switch (state) {
        case SyncState.queued:
          queued += n;
        case SyncState.syncing:
          syncing += n;
        case SyncState.failed:
          failed += n;
        case SyncState.synced:
        case null:
          break;
      }
    }
    return OutboxSummary(queued: queued, syncing: syncing, failed: failed);
  }

  Future<void> _emitSummary() async {
    if (_changes.isClosed) return;
    _changes.add(await summary());
  }

  /// Moves [visitId] to [state] as delivery progresses. A Visit not in the
  /// outbox is left untouched.
  Future<void> setSyncState(String visitId, SyncState state) async {
    await (_database.update(_database.outboxEntries)
          ..where((table) => table.visitId.equals(visitId)))
        .write(OutboxEntriesCompanion(syncState: Value(state)));
    await _emitSummary();
  }
}
