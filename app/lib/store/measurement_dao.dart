import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../features/visits/measurement.dart';
import 'app_database.dart';
import 'database_provider.dart';

final measurementDaoProvider = Provider<MeasurementDao>(
  (ref) => MeasurementDao(ref.watch(databaseProvider)),
);

/// Persists the Measurements recorded against a Visit's covariates.
///
/// A [Measurement] always carries its [Provenance] with a method (INV-010),
/// so this DAO has no path that stores one without it: [record] takes the
/// value object whole and writes its provenance as JSON.
class MeasurementDao {
  MeasurementDao(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  /// Records a Measurement for [visitId] and returns it.
  Future<Measurement> record({
    required String visitId,
    required Measurement measurement,
    String? id,
  }) async {
    await _database
        .into(_database.measurements)
        .insert(
          MeasurementsCompanion.insert(
            id: id ?? _uuid.v7(),
            visitId: visitId,
            name: measurement.name,
            value: measurement.value,
            unit: Value(measurement.unit),
            provenance: jsonEncode(measurement.provenance.toJson()),
          ),
        );
    return measurement;
  }

  /// The Measurements recorded for a Visit.
  Future<List<Measurement>> forVisit(String visitId) async {
    final rows = await (_database.select(
      _database.measurements,
    )..where((table) => table.visitId.equals(visitId))).get();
    return rows.map(_toMeasurement).toList(growable: false);
  }

  Measurement _toMeasurement(MeasurementRow row) => Measurement(
    name: row.name,
    value: row.value,
    unit: row.unit,
    provenance: Provenance.fromJson(
      jsonDecode(row.provenance) as Map<String, Object?>,
    ),
  );
}
