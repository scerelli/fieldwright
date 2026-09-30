import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/measurement.dart';
import 'package:ibis/features/visits/sensor_service.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/measurement_dao.dart';
import 'package:ibis/store/visit_dao.dart';

const CovariateDefinition _windSpeed = CovariateDefinition(
  name: 'windSpeed',
  type: CovariateDefinitionType.number,
  unit: 'm/s',
);

ProtocolDocument _document() => const ProtocolDocument(
  protocolId: 'alpine-birds',
  version: 1,
  taxonomicScope: TaxonomicScope(taxa: ['Aves']),
  detectionMethods: [DetectionMethod(id: 'visual', label: 'Visual')],
  requiredEffortFields: [SamplingEffortField.start],
  visitCovariates: [_windSpeed],
);

Future<Visit> _startVisit(AppDatabase database) => VisitDao(database)
    .startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
    );

/// A [SensorService] whose result is fixed, so widget tests exercise the
/// missing-sensor and uncalibrated states without touching a platform channel.
class _FakeSensorService implements SensorService {
  _FakeSensorService(this.sensorValue);

  final SensorValue? sensorValue;
  final List<String> readFields = <String>[];

  @override
  Future<SensorValue?> read(CovariateDefinition field) async {
    readFields.add(field.name);
    return sensorValue;
  }
}

Future<void> _pumpCapture(
  WidgetTester tester, {
  required AppDatabase database,
  required Visit visit,
  required SensorService sensor,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        sensorServiceProvider.overrideWithValue(sensor),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CaptureScreen(visit: visit, protocol: _document()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Measurement', () {
    test('carries its value, unit and provenance method', () {
      final measurement = buildMeasurement(
        name: 'windSpeed',
        value: '4.2',
        unit: 'm/s',
        method: ProvenanceMethod.phoneSensor,
      );

      expect(measurement, isNotNull);
      expect(measurement!.name, 'windSpeed');
      expect(measurement.value, '4.2');
      expect(measurement.unit, 'm/s');
      expect(measurement.provenance.method, ProvenanceMethod.phoneSensor);
      expect(measurement.isLowConfidence, isFalse);
    });

    test('rejects a value without a method (INV-010)', () {
      expect(
        buildMeasurement(
          name: 'windSpeed',
          value: '4.2',
          unit: 'm/s',
          method: null,
        ),
        isNull,
      );
    });

    test('marks an uncalibrated sensor value low-confidence', () {
      final uncalibrated = buildMeasurement(
        name: 'windSpeed',
        value: '4.2',
        unit: 'm/s',
        method: ProvenanceMethod.phoneSensor,
        calibration: CalibrationState.uncalibrated,
      );
      final calibrated = buildMeasurement(
        name: 'windSpeed',
        value: '4.2',
        unit: 'm/s',
        method: ProvenanceMethod.phoneSensor,
      );

      expect(uncalibrated!.isLowConfidence, isTrue);
      expect(calibrated!.isLowConfidence, isFalse);
    });

    test('serializes to JSON and rejects an unknown method', () {
      final measurement = buildMeasurement(
        name: 'windSpeed',
        value: '4.2',
        unit: 'm/s',
        method: ProvenanceMethod.fieldInstrument,
        instrument: 'Kestrel 5500',
        observer: 'collector-1',
      )!;

      expect(
        Measurement.fromJson(measurement.toJson()).toJson(),
        measurement.toJson(),
      );
      expect(
        () => Provenance.fromJson(const {'method': 'telepathy'}),
        throwsFormatException,
      );
      expect(
        () => Provenance.fromJson(const {'method': 'phoneSensor'}),
        returnsNormally,
      );
    });
  });

  group('MeasurementDao', () {
    test('persists a Measurement with its provenance for a Visit', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _startVisit(database);
      final dao = MeasurementDao(database);

      await dao.record(
        visitId: visit.id,
        measurement: buildMeasurement(
          name: 'windSpeed',
          value: '4.2',
          unit: 'm/s',
          method: ProvenanceMethod.phoneSensor,
          calibration: CalibrationState.uncalibrated,
        )!,
      );

      final stored = await dao.forVisit(visit.id);
      expect(stored, hasLength(1));
      expect(stored.single.name, 'windSpeed');
      expect(stored.single.value, '4.2');
      expect(stored.single.unit, 'm/s');
      expect(stored.single.provenance.method, ProvenanceMethod.phoneSensor);
      expect(stored.single.isLowConfidence, isTrue);
    });
  });

  group('capture screen covariates', () {
    testWidgets(
      'falls back to manual entry when the sensor is missing (UX-011)',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visit = await _startVisit(database);
        final sensor = _FakeSensorService(null);

        await _pumpCapture(
          tester,
          database: database,
          visit: visit,
          sensor: sensor,
        );

        expect(sensor.readFields, ['windSpeed']);
        expect(
          find.byKey(const Key('covariate_manual_windSpeed')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('measurement_manual_fallback_windSpeed')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('covariate_low_confidence_windSpeed')),
          findsNothing,
        );

        await tester.enterText(
          find.byKey(const Key('covariate_manual_windSpeed')),
          '5',
        );
        await tester.tap(find.byKey(const Key('covariate_method_windSpeed')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Visual estimate').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('measurements_save')));
        await tester.pumpAndSettle();

        final stored = await MeasurementDao(database).forVisit(visit.id);
        expect(stored, hasLength(1));
        expect(stored.single.value, '5');
        expect(
          stored.single.provenance.method,
          ProvenanceMethod.visualEstimate,
        );
      },
    );

    testWidgets('marks an uncalibrated sensor value low-confidence', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _startVisit(database);
      final sensor = _FakeSensorService(
        const SensorValue(
          value: 4.2,
          calibration: CalibrationState.uncalibrated,
        ),
      );

      await _pumpCapture(
        tester,
        database: database,
        visit: visit,
        sensor: sensor,
      );

      expect(find.byKey(const Key('covariate_manual_windSpeed')), findsNothing);
      expect(
        find.byKey(const Key('covariate_low_confidence_windSpeed')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('measurements_save')));
      await tester.pumpAndSettle();

      final stored = await MeasurementDao(database).forVisit(visit.id);
      expect(stored, hasLength(1));
      expect(stored.single.provenance.method, ProvenanceMethod.phoneSensor);
      expect(stored.single.isLowConfidence, isTrue);
    });
  });

  group('migration', () {
    test(
      'migrates a version 7 client schema to version 8 forward-only',
      () async {
        final database = AppDatabase(
          NativeDatabase.memory(
            setup: (raw) {
              raw.execute('''
CREATE TABLE sites (
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  geometry TEXT NOT NULL,
  origin TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  location_provenance TEXT,
  covariates TEXT,
  PRIMARY KEY (id)
);
''');
              raw.execute('''
CREATE TABLE visits (
  id TEXT NOT NULL,
  site_id TEXT NOT NULL,
  survey_period_id TEXT NOT NULL,
  protocol_version_id TEXT NOT NULL,
  state TEXT NOT NULL,
  effort_started_at INTEGER NOT NULL,
  effort_ended_at INTEGER,
  PRIMARY KEY (id)
);
''');
              raw.execute('''
CREATE TABLE detections (
  visit_id TEXT NOT NULL,
  taxon_ref TEXT NOT NULL,
  detected INTEGER NOT NULL,
  opportunistic INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (visit_id, taxon_ref)
);
''');
              raw.execute('''
CREATE TABLE evidences (
  id TEXT NOT NULL,
  visit_id TEXT NOT NULL,
  taxon_ref TEXT NOT NULL,
  kind TEXT NOT NULL,
  file_path TEXT NOT NULL,
  captured_at INTEGER NOT NULL,
  content_hash TEXT NOT NULL,
  PRIMARY KEY (id)
);
''');
              raw.execute(
                "INSERT INTO visits (id, site_id, survey_period_id, protocol_version_id, state, effort_started_at) "
                "VALUES ('visit-1', 'site-1', 'survey-period-1', 'protocol-version-1', 'inProgress', 1767225600);",
              );
              raw.execute('PRAGMA user_version = 7');
            },
          ),
        );
        addTearDown(database.close);

        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 8);

        final tables = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'measurements'",
            )
            .get();
        expect(tables, hasLength(1));

        final dao = MeasurementDao(database);
        await dao.record(
          visitId: 'visit-1',
          measurement: buildMeasurement(
            name: 'windSpeed',
            value: '4.2',
            unit: 'm/s',
            method: ProvenanceMethod.phoneSensor,
          )!,
        );
        expect((await dao.forVisit('visit-1')), hasLength(1));
      },
    );
  });
}
