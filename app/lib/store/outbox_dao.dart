import 'package:drift/drift.dart';

import '../outbox/outbox.dart';
import 'app_database.dart';

/// Reads and writes the client outbox: the queue of ended Visits awaiting
/// delivery, each carrying its [SyncState]. Rows live in the local store, so a
/// queued submission survives an app relaunch (UX-013).
class OutboxDao {
  OutboxDao(this._database);

  final AppDatabase _database;

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
  }

  /// The sync state recorded for [visitId], or `null` when the Visit is not in
  /// the outbox.
  Future<SyncState?> syncStateOf(String visitId) async {
    final row = await (_database.select(
      _database.outboxEntries,
    )..where((table) => table.visitId.equals(visitId))).getSingleOrNull();
    return row?.syncState;
  }

  /// Moves [visitId] to [state] as delivery progresses. A Visit not in the
  /// outbox is left untouched.
  Future<void> setSyncState(String visitId, SyncState state) async {
    await (_database.update(_database.outboxEntries)
          ..where((table) => table.visitId.equals(visitId)))
        .write(OutboxEntriesCompanion(syncState: Value(state)));
  }
}
