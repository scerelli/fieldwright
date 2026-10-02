import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/detection.dart';
import 'package:ibis/features/visits/evidence.dart';
import 'package:ibis/features/visits/measurement.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/features/visits/visit_recovery.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/detection_dao.dart';
import 'package:ibis/store/evidence_dao.dart';
import 'package:ibis/store/measurement_dao.dart';
import 'package:ibis/store/visit_dao.dart';

Future<Visit> _startVisit(AppDatabase database, {String? id, DateTime? now}) =>
    VisitDao(database).startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
      id: id,
      now: now,
    );

void main() {
  test('every change to an in-progress Visit is written to the local store immediately', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final visit = await _startVisit(database);
    await container
        .read(detectionDaoProvider)
        .record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Turdus|merula',
            detected: false,
            method: 'visual',
          ),
        );

    final recovered = await container.read(inProgressVisitProvider.future);

    expect(recovered, isNotNull);
    expect(recovered!.visit.id, visit.id);
    expect(recovered.visit.state, VisitState.inProgress);
    expect(recovered.detections, hasLength(1));
    expect(recovered.detections.single.taxonRef, 'Aves|Turdus|merula');
    expect(recovered.detections.single.detected, isFalse);
  });

  test('a forced kill and relaunch against the same database restores the in-progress Visit and its data', () async {
    final directory = Directory.systemTemp.createTempSync('ibis_recovery');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/ibis.sqlite';
    final startedAt = DateTime.utc(2026, 5, 1, 8, 0);

    var database = AppDatabase.open(path);
    var container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );

    final visit = await _startVisit(database, id: 'visit-1', now: startedAt);
    await container
        .read(detectionDaoProvider)
        .record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Turdus|merula',
            detected: true,
            method: 'visual',
          ),
        );
    await container
        .read(evidenceDaoProvider)
        .attach(
          visitId: visit.id,
          taxonRef: 'Aves|Turdus|merula',
          kind: EvidenceKind.photo,
          filePath: '/data/evidence/visit-1.jpg',
          contentHash: 'hash',
          capturedAt: startedAt,
        );
    await container
        .read(measurementDaoProvider)
        .record(
          visitId: visit.id,
          measurement: buildMeasurement(
            name: 'windSpeed',
            value: '4.2',
            unit: 'm/s',
            method: ProvenanceMethod.phoneSensor,
          )!,
        );

    // Forced kill: drop every provider and close the database with no
    // further write.
    expect(await container.read(inProgressVisitProvider.future), isNotNull);
    container.dispose();
    await database.close();

    // Relaunch against the same database file.
    database = AppDatabase.open(path);
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    final restored = await container.read(inProgressVisitProvider.future);
    final evidence = await container
        .read(evidenceDaoProvider)
        .forVisit('visit-1');
    final measurements = await container
        .read(measurementDaoProvider)
        .forVisit('visit-1');
    container.dispose();
    await database.close();

    expect(restored, isNotNull);
    expect(restored!.visit.id, 'visit-1');
    expect(restored.visit.state, VisitState.inProgress);
    expect(restored.visit.effort.startedAt, startedAt);
    expect(restored.detections, hasLength(1));
    expect(restored.detections.single.taxonRef, 'Aves|Turdus|merula');
    expect(restored.detections.single.detected, isTrue);
    expect(evidence, hasLength(1));
    expect(measurements, hasLength(1));
  });

  testWidgets(
    'the capture screen reads the in-progress Visit from the store, not from memory',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _startVisit(database);
      // An in-memory Visit that disagrees with the store: the capture screen
      // must show the stored one.
      final stale = visit.copyWith(
        state: VisitState.ended,
        effort: visit.effort.copyWith(endedAt: DateTime.utc(2026, 5, 1, 9, 0)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CaptureScreen(visit: stale),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('State: In progress'), findsOneWidget);
      expect(find.text('State: Ended'), findsNothing);
    },
  );
}
