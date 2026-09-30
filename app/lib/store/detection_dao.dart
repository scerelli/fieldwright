import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/visits/detection.dart';
import 'app_database.dart';
import 'database_provider.dart';

final detectionDaoProvider = Provider<DetectionDao>(
  (ref) => DetectionDao(ref.watch(databaseProvider)),
);

/// Persists the Detection records of a Visit. A Detection's identity is the
/// pair of visit and target taxon, so recording a taxon a second time replaces
/// its record rather than adding another (ARCHITECTURE.md › data model).
class DetectionDao {
  DetectionDao(this._database);

  final AppDatabase _database;

  Future<void> record(Detection detection) async {
    await _database
        .into(_database.detections)
        .insertOnConflictUpdate(_toCompanion(detection));
  }

  Future<Detection?> find(String visitId, String taxonRef) async {
    final row =
        await (_database.select(_database.detections)..where(
              (table) =>
                  table.visitId.equals(visitId) &
                  table.taxonRef.equals(taxonRef),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDetection(row);
  }

  Future<List<Detection>> forVisit(String visitId) async {
    final rows = await (_database.select(
      _database.detections,
    )..where((table) => table.visitId.equals(visitId))).get();
    return rows.map(_toDetection).toList(growable: false);
  }

  DetectionsCompanion _toCompanion(Detection detection) =>
      DetectionsCompanion.insert(
        visitId: detection.visitId,
        taxonRef: detection.taxonRef,
        detected: detection.detected,
        opportunistic: Value(detection.opportunistic),
      );

  Detection _toDetection(DetectionRow row) => Detection(
    visitId: row.visitId,
    taxonRef: row.taxonRef,
    detected: row.detected,
    opportunistic: row.opportunistic,
  );
}
