import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../features/visits/visit.dart';
import '../protocol/protocol.dart';
import 'app_database.dart';

class VisitDao {
  VisitDao(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<Visit> startVisit({
    required String siteId,
    String? surveyPeriodId,
    String? protocolVersionId,
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
    if (!visit.isInProgress) {
      throw StateError('Use endVisit to end a Visit');
    }
    final existing = await findById(visit.id);
    if (existing != null && !existing.isInProgress) {
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
    if (!existing.isInProgress) {
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

  /// Marks the ended Visit [id] as delivered to the server, moving it to the
  /// `submitted` lifecycle state (DOMAIN.md). Idempotent: an already submitted
  /// Visit is returned unchanged, and the transition is only legal from
  /// [VisitState.ended] — a submitted Visit is immutable thereafter (INV-001).
  Future<Visit> markSubmitted(String id) async {
    final existing = await findById(id);
    if (existing == null) {
      throw StateError('Cannot submit a Visit that was not started');
    }
    if (existing.isSubmitted) {
      return existing;
    }
    if (!existing.isEnded) {
      throw StateError('Only an ended Visit can be marked submitted');
    }
    final submitted = existing.copyWith(state: VisitState.submitted);
    await _database
        .into(_database.visits)
        .insertOnConflictUpdate(_toCompanion(submitted));
    return submitted;
  }

  /// Records [observers] as the Visit [id]'s `observers` Sampling-effort field
  /// (INV-005). Observers are effort, not lifecycle, so this is legal while the
  /// Visit is in progress or ended; a submitted Visit is immutable (INV-001).
  Future<Visit> recordObservers(String id, List<String> observers) async {
    final existing = await findById(id);
    if (existing == null) {
      throw StateError(
        'Cannot record observers for a Visit that was not started',
      );
    }
    if (existing.isSubmitted) {
      throw StateError('A submitted Visit is immutable');
    }
    final updated = existing.copyWith(
      effort: existing.effort.copyWith(observers: observers),
    );
    await _database
        .into(_database.visits)
        .insertOnConflictUpdate(_toCompanion(updated));
    return updated;
  }

  /// The `requiredEffortFields` of the Protocol version [visit] references, as
  /// cached in the local store. Empty when the version is not cached, so the
  /// server stays the authority for a Visit it has never seen a protocol for.
  Future<List<SamplingEffortField>> requiredEffortFieldsFor(Visit visit) async {
    final protocolVersionId = visit.protocolVersionId;
    if (protocolVersionId == null) return const <SamplingEffortField>[];
    final row = await (_database.select(
      _database.protocolVersions,
    )..where((table) => table.id.equals(protocolVersionId))).getSingleOrNull();
    if (row == null) return const <SamplingEffortField>[];
    final document = ProtocolDocument.fromJson(
      jsonDecode(row.document) as Map<String, dynamic>,
    );
    return document.requiredEffortFields;
  }

  /// The distinct Detection methods the Visit [visitId]'s Detections record
  /// (the `detectionMethods` Sampling-effort field, INV-005), sorted for a
  /// stable payload.
  Future<List<String>> detectionMethodsFor(String visitId) async {
    final rows = await (_database.select(
      _database.detections,
    )..where((table) => table.visitId.equals(visitId))).get();
    final methods = <String>{
      for (final row in rows)
        if (row.method != null && row.method!.trim().isNotEmpty) row.method!,
    };
    return methods.toList()..sort();
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

  /// The Visits still in progress, most recently started first. The app
  /// resumes the first of these on relaunch (UX-013).
  Future<List<Visit>> inProgress() async {
    final rows =
        await (_database.select(_database.visits)
              ..where((table) => table.state.equalsValue(VisitState.inProgress))
              ..orderBy([(table) => OrderingTerm.desc(table.effortStartedAt)]))
            .get();
    return rows.map(_toVisit).toList(growable: false);
  }

  VisitsCompanion _toCompanion(Visit visit) => VisitsCompanion.insert(
    id: visit.id,
    siteId: visit.siteId,
    surveyPeriodId: Value(visit.surveyPeriodId),
    protocolVersionId: Value(visit.protocolVersionId),
    state: visit.state,
    effortStartedAt: visit.effort.startedAt,
    effortEndedAt: Value(visit.effort.endedAt),
    effortObservers: Value(jsonEncode(visit.effort.observers)),
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
      observers: _decodeObservers(row.effortObservers),
    ),
  );
}

List<String> _decodeObservers(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const <String>[];
  final decoded = jsonDecode(encoded);
  if (decoded is! List) return const <String>[];
  return <String>[
    for (final value in decoded)
      if (value is String) value,
  ];
}
