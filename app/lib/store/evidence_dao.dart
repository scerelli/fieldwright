import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../features/visits/evidence.dart';
import 'app_database.dart';
import 'database_provider.dart';

final evidenceDaoProvider = Provider<EvidenceDao>(
  (ref) => EvidenceDao(ref.watch(databaseProvider)),
);

/// Persists the Evidence attached to a Visit's Detections.
///
/// The store is append-only by design: Evidence is immutable once attached
/// (DOMAIN.md › Evidence), so this DAO exposes only [attach] and the reads
/// [findById], [forDetection] and [forVisit] — there is no update or delete
/// path anywhere in the client.
class EvidenceDao {
  EvidenceDao(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  /// Attaches a new Evidence to a Detection and returns it. The Evidence is
  /// inserted, never upserted: a conflicting id raises instead of overwriting,
  /// so an attached Evidence can never be rewritten.
  Future<Evidence> attach({
    required String visitId,
    required String taxonRef,
    required EvidenceKind kind,
    required String filePath,
    required String contentHash,
    required DateTime capturedAt,
    String? id,
  }) async {
    final evidence = Evidence(
      id: id ?? _uuid.v7(),
      visitId: visitId,
      taxonRef: taxonRef,
      kind: kind,
      filePath: filePath,
      capturedAt: capturedAt,
      contentHash: contentHash,
    );
    await _database.into(_database.evidences).insert(_toCompanion(evidence));
    return evidence;
  }

  Future<Evidence?> findById(String id) async {
    final row = await (_database.select(
      _database.evidences,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEvidence(row);
  }

  /// The Evidence attached to one Detection, identified by its Visit and
  /// target taxon.
  Future<List<Evidence>> forDetection(String visitId, String taxonRef) async {
    final rows =
        await (_database.select(_database.evidences)..where(
              (table) =>
                  table.visitId.equals(visitId) &
                  table.taxonRef.equals(taxonRef),
            ))
            .get();
    return rows.map(_toEvidence).toList(growable: false);
  }

  Future<List<Evidence>> forVisit(String visitId) async {
    final rows = await (_database.select(
      _database.evidences,
    )..where((table) => table.visitId.equals(visitId))).get();
    return rows.map(_toEvidence).toList(growable: false);
  }

  EvidencesCompanion _toCompanion(Evidence evidence) =>
      EvidencesCompanion.insert(
        id: evidence.id,
        visitId: evidence.visitId,
        taxonRef: evidence.taxonRef,
        kind: evidence.kind,
        filePath: evidence.filePath,
        capturedAt: evidence.capturedAt,
        contentHash: evidence.contentHash,
      );

  Evidence _toEvidence(EvidenceRow row) => Evidence(
    id: row.id,
    visitId: row.visitId,
    taxonRef: row.taxonRef,
    kind: row.kind,
    filePath: row.filePath,
    capturedAt: row.capturedAt.toUtc(),
    contentHash: row.contentHash,
  );
}
