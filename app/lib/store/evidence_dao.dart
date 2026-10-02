import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../features/visits/evidence.dart';
import '../features/visits/visit.dart';
import 'app_database.dart';
import 'database_provider.dart';

final evidenceDaoProvider = Provider<EvidenceDao>(
  (ref) => EvidenceDao(ref.watch(databaseProvider)),
);

/// Persists the Evidence attached to a Visit's Detections.
///
/// Evidence is immutable once attached (DOMAIN.md › Evidence): this DAO
/// exposes [attach] and the reads [findById], [forDetection] and [forVisit].
/// The one field outside that immutability is the transport [storageKey],
/// filled in once by [markUploaded] after a successful media upload — there is
/// no delete path anywhere in the client.
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

  /// Persists the content-addressed [storageKey] the media API returned for an
  /// Evidence, so a later submission carries it in the evidence manifest. The
  /// Evidence's own content is untouched; a row that already carries a key is
  /// left as it is, so an uploaded Evidence is never rewritten.
  ///
  /// Refuses when the owning Visit is already `submitted`: a submitted Visit is
  /// never edited (INV-001), and an upload — retryable by design — must not
  /// mutate its Evidence. A Visit with no local row is not submitted.
  Future<void> markUploaded(String id, String storageKey) async {
    final row = await (_database.select(
      _database.evidences,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null || row.storageKey != null) {
      return;
    }
    final visit = await (_database.select(
      _database.visits,
    )..where((table) => table.id.equals(row.visitId))).getSingleOrNull();
    if (visit != null && visit.state == VisitState.submitted) {
      throw StateError('Cannot upload Evidence of a submitted Visit');
    }
    await (_database.update(_database.evidences)
          ..where(
            (table) => table.id.equals(id) & table.storageKey.isNull(),
          ))
        .write(EvidencesCompanion(storageKey: Value(storageKey)));
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
        storageKey: Value(evidence.storageKey),
      );

  Evidence _toEvidence(EvidenceRow row) => Evidence(
    id: row.id,
    visitId: row.visitId,
    taxonRef: row.taxonRef,
    kind: row.kind,
    filePath: row.filePath,
    capturedAt: row.capturedAt.toUtc(),
    contentHash: row.contentHash,
    storageKey: row.storageKey,
  );
}
