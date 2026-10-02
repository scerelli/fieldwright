import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/visits/determination.dart';
import 'app_database.dart';
import 'database_provider.dart';

final determinationDaoProvider = Provider<DeterminationDao>(
  (ref) => DeterminationDao(ref.watch(databaseProvider)),
);

/// Persists the Determinations of a Detection, identified by its Visit and
/// target taxon.
///
/// Append-only by design (INV-009): a revision is a new Determination whose
/// `replacesId` names the one it replaces, so this DAO exposes only [append]
/// and the reads [findById], [forDetection] and [forVisit] — there is no update
/// path anywhere in the client. [append] inserts rather than upserts, so a
/// conflicting id raises instead of overwriting a stored Determination.
class DeterminationDao {
  DeterminationDao(this._database);

  final AppDatabase _database;

  Future<void> append({
    required String visitId,
    required String taxonRef,
    required Determination determination,
  }) async {
    await _database
        .into(_database.determinations)
        .insert(_toCompanion(visitId, taxonRef, determination));
  }

  Future<Determination?> findById(String id) async {
    final row = await (_database.select(
      _database.determinations,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDetermination(row);
  }

  /// The Determinations recorded for one Detection, identified by its Visit
  /// and target taxon, in insertion order (`rowid`).
  ///
  /// The append-only chain needs a deterministic order: a revision is appended
  /// after the Determination it replaces (INV-009), and the submission nests
  /// them so that a revision's `replacesIndex` can point back at its
  /// predecessor. `rowid` gives exactly that append order, which the unordered
  /// read did not.
  Future<List<Determination>> forDetection(
    String visitId,
    String taxonRef,
  ) async {
    final rows =
        await (_database.select(_database.determinations)
              ..where(
                (table) =>
                    table.visitId.equals(visitId) &
                    table.taxonRef.equals(taxonRef),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.rowId)]))
            .get();
    return rows.map(_toDetermination).toList(growable: false);
  }

  Future<List<Determination>> forVisit(String visitId) async {
    final rows = await (_database.select(
      _database.determinations,
    )..where((table) => table.visitId.equals(visitId))).get();
    return rows.map(_toDetermination).toList(growable: false);
  }

  DeterminationsCompanion _toCompanion(
    String visitId,
    String taxonRef,
    Determination determination,
  ) => DeterminationsCompanion.insert(
    id: determination.id,
    visitId: visitId,
    taxonRef: taxonRef,
    taxon: determination.taxon,
    qualifier: Value(determination.qualifier),
    specimenCode: Value(determination.specimenCode),
    determiner: determination.determiner,
    date: determination.date,
    replacesId: Value(determination.replacesId),
  );

  Determination _toDetermination(DeterminationRow row) => Determination(
    id: row.id,
    taxon: row.taxon,
    qualifier: row.qualifier,
    specimenCode: row.specimenCode,
    determiner: row.determiner,
    date: row.date.toUtc(),
    replacesId: row.replacesId,
  );
}
