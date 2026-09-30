import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../features/visits/visit.dart';
import 'app_database.dart';

class VisitDao {
  VisitDao(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<Visit> startVisit({
    required String siteId,
    required String surveyPeriodId,
    required String protocolVersionId,
    String? id,
    DateTime? now,
  }) async {
    final visit = Visit(
      id: id ?? _uuid.v7(),
      siteId: siteId,
      surveyPeriodId: surveyPeriodId,
      protocolVersionId: protocolVersionId,
      state: VisitState.inProgress,
      effort: SamplingEffort(startedAt: (now ?? DateTime.now()).toUtc()),
    );
    await _database.into(_database.visits).insert(_toCompanion(visit));
    return visit;
  }

  Future<void> save(Visit visit) async {
    if (visit.isEnded) {
      throw StateError('Use endVisit to end a Visit');
    }
    final existing = await findById(visit.id);
    if (existing?.isEnded ?? false) {
      throw StateError('An ended Visit rejects further in-progress changes');
    }
    await _database
        .into(_database.visits)
        .insertOnConflictUpdate(_toCompanion(visit));
  }

  Future<Visit> endVisit(Visit visit, {DateTime? now}) async {
    final existing = await findById(visit.id);
    if (existing == null) {
      throw StateError('Cannot end a Visit that was not started');
    }
    if (existing.isEnded) {
      throw StateError('An ended Visit rejects further in-progress changes');
    }
    final ended = existing.copyWith(
      state: VisitState.ended,
      effort: existing.effort.copyWith(
        endedAt: (now ?? DateTime.now()).toUtc(),
      ),
    );
    await _database
        .into(_database.visits)
        .insertOnConflictUpdate(_toCompanion(ended));
    return ended;
  }

  Future<Visit?> findById(String id) async {
    final row = await (_database.select(
      _database.visits,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toVisit(row);
  }

  Future<List<Visit>> all() async {
    final rows = await _database.select(_database.visits).get();
    return rows.map(_toVisit).toList(growable: false);
  }

  VisitsCompanion _toCompanion(Visit visit) => VisitsCompanion.insert(
    id: visit.id,
    siteId: visit.siteId,
    surveyPeriodId: visit.surveyPeriodId,
    protocolVersionId: visit.protocolVersionId,
    state: visit.state,
    effortStartedAt: visit.effort.startedAt,
    effortEndedAt: Value(visit.effort.endedAt),
  );

  Visit _toVisit(VisitRow row) => Visit(
    id: row.id,
    siteId: row.siteId,
    surveyPeriodId: row.surveyPeriodId,
    protocolVersionId: row.protocolVersionId,
    state: row.state,
    effort: SamplingEffort(
      startedAt: row.effortStartedAt.toUtc(),
      endedAt: row.effortEndedAt?.toUtc(),
    ),
  );
}
