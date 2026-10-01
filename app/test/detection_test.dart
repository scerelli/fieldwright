import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/detection.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/detection_dao.dart';
import 'package:ibis/store/visit_dao.dart';

List<TargetTaxon> _targets() => const <TargetTaxon>[
  TargetTaxon(taxonRef: 'Aves|Turdus|merula', label: 'Common blackbird'),
  TargetTaxon(taxonRef: 'Aves|Erithacus|rubecula', label: 'European robin'),
];

ProtocolDocument _document({
  List<TargetTaxon>? targets,
  List<DetectionMethod> methods = const [
    DetectionMethod(id: 'visual', label: 'Visual'),
  ],
}) => ProtocolDocument(
  protocolId: 'alpine-birds',
  version: 1,
  taxonomicScope: const TaxonomicScope(taxa: ['Aves']),
  detectionMethods: methods,
  requiredEffortFields: const [SamplingEffortField.start],
  targetList: targets ?? _targets(),
);

Future<Visit> _startVisit(AppDatabase database, {String? id}) =>
    VisitDao(database).startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
      id: id,
    );

Future<void> _pumpCapture(
  WidgetTester tester, {
  required AppDatabase database,
  required Visit visit,
  ProtocolDocument? protocol,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CaptureScreen(visit: visit, protocol: protocol),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Key _detected(String taxonRef) => Key('detection_detected_$taxonRef');
Key _notDetected(String taxonRef) => Key('detection_not_detected_$taxonRef');
Key _notRecorded(String taxonRef) => Key('detection_not_recorded_$taxonRef');
Key _active(String taxonRef) => Key('detection_active_$taxonRef');
Key _methodField() => const Key('detection_method');
Key _control(String taxonRef) => Key('detection_control_$taxonRef');

Future<void> _chooseMethod(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(_methodField()));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('Detection', () {
    test('carries the visit, the taxon and the detected flag', () {
      const detection = Detection(
        visitId: 'visit-1',
        taxonRef: 'Aves|Turdus|merula',
        detected: false,
      );

      expect(detection.visitId, 'visit-1');
      expect(detection.taxonRef, 'Aves|Turdus|merula');
      expect(detection.detected, isFalse);
    });

    test('copyWith changes only the detected flag', () {
      const detection = Detection(
        visitId: 'visit-1',
        taxonRef: 'Aves|Turdus|merula',
        detected: false,
      );

      final changed = detection.copyWith(detected: true);

      expect(changed.detected, isTrue);
      expect(changed.visitId, detection.visitId);
      expect(changed.taxonRef, detection.taxonRef);
    });

    test('two Detections for the same visit and taxon are equal', () {
      const first = Detection(
        visitId: 'visit-1',
        taxonRef: 'Aves|Turdus|merula',
        detected: true,
      );
      const second = Detection(
        visitId: 'visit-1',
        taxonRef: 'Aves|Turdus|merula',
        detected: true,
      );

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });
  });

  group('target completeness', () {
    test('reports every target taxon without a Detection as unrecorded', () {
      final unrecorded = unrecordedTargets(_targets(), const <Detection>[]);

      expect(unrecorded.map((target) => target.taxonRef), [
        'Aves|Turdus|merula',
        'Aves|Erithacus|rubecula',
      ]);
    });

    test('treats a non-detection as recorded, not as unrecorded', () {
      final detections = <Detection>[
        const Detection(
          visitId: 'visit-1',
          taxonRef: 'Aves|Turdus|merula',
          detected: false,
        ),
      ];

      final unrecorded = unrecordedTargets(_targets(), detections);

      expect(unrecorded.map((target) => target.taxonRef), [
        'Aves|Erithacus|rubecula',
      ]);
    });

    test('allTargetsRecorded is false while any target is unrecorded', () {
      expect(allTargetsRecorded(_targets(), const <Detection>[]), isFalse);
    });

    test('allTargetsRecorded is true once every target has a Detection', () {
      final detections = <Detection>[
        const Detection(
          visitId: 'visit-1',
          taxonRef: 'Aves|Turdus|merula',
          detected: true,
        ),
        const Detection(
          visitId: 'visit-1',
          taxonRef: 'Aves|Erithacus|rubecula',
          detected: false,
        ),
      ];

      expect(allTargetsRecorded(_targets(), detections), isTrue);
    });
  });

  group('DetectionDao', () {
    test('persists and reloads a Detection\'s method and count', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final dao = DetectionDao(database);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );

      await dao.record(
        Detection(
          visitId: visit.id,
          taxonRef: 'Aves|Turdus|merula',
          detected: true,
          method: 'visual',
          count: 3,
        ),
      );

      final stored = await dao.find(visit.id, 'Aves|Turdus|merula');
      expect(stored, isNotNull);
      expect(stored!.method, 'visual');
      expect(stored.count, 3);
    });

    test('rejects a Detection persisted without a method', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final dao = DetectionDao(database);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );

      await expectLater(
        dao.record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Turdus|merula',
            detected: true,
          ),
        ),
        throwsArgumentError,
      );
      await expectLater(
        dao.record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Turdus|merula',
            detected: true,
            method: '   ',
          ),
        ),
        throwsArgumentError,
      );
      expect(await dao.forVisit(visit.id), isEmpty);
    });

    test('records one Detection per target taxon of the protocol', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final dao = DetectionDao(database);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );

      for (final target in _targets()) {
        await dao.record(
          Detection(
            visitId: visit.id,
            taxonRef: target.taxonRef,
            detected: true,
            method: 'visual',
          ),
        );
      }

      final stored = await dao.forVisit(visit.id);
      expect(stored, hasLength(_targets().length));
      expect(stored.map((detection) => detection.taxonRef).toSet(), {
        'Aves|Turdus|merula',
        'Aves|Erithacus|rubecula',
      });
      expect(stored.every((detection) => detection.detected), isTrue);
    });

    test(
      'a non-detection is stored as a Detection with detected false',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final dao = DetectionDao(database);
        final visit = await VisitDao(database).startVisit(
          siteId: 'site-1',
          surveyPeriodId: 'survey-period-1',
          protocolVersionId: 'protocol-version-1',
        );

        await dao.record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Turdus|merula',
            detected: false,
            method: 'visual',
          ),
        );

        final stored = await dao.find(visit.id, 'Aves|Turdus|merula');
        expect(stored, isNotNull);
        expect(stored!.detected, isFalse);
        expect(await dao.forVisit(visit.id), hasLength(1));
      },
    );

    test(
      're-recording a target replaces its Detection without duplicating it',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final dao = DetectionDao(database);
        final visit = await VisitDao(database).startVisit(
          siteId: 'site-1',
          surveyPeriodId: 'survey-period-1',
          protocolVersionId: 'protocol-version-1',
        );

        await dao.record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Turdus|merula',
            detected: true,
            method: 'visual',
          ),
        );
        await dao.record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Turdus|merula',
            detected: false,
            method: 'visual',
          ),
        );

        final stored = await dao.forVisit(visit.id);
        expect(stored, hasLength(1));
        expect(stored.single.detected, isFalse);
      },
    );

    test(
      'a visit is complete only once every target taxon is stored',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final dao = DetectionDao(database);
        final visit = await VisitDao(database).startVisit(
          siteId: 'site-1',
          surveyPeriodId: 'survey-period-1',
          protocolVersionId: 'protocol-version-1',
        );

        expect(
          allTargetsRecorded(_targets(), await dao.forVisit(visit.id)),
          isFalse,
        );

        await dao.record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Turdus|merula',
            detected: true,
            method: 'visual',
          ),
        );
        expect(
          allTargetsRecorded(_targets(), await dao.forVisit(visit.id)),
          isFalse,
        );

        await dao.record(
          Detection(
            visitId: visit.id,
            taxonRef: 'Aves|Erithacus|rubecula',
            detected: false,
            method: 'visual',
          ),
        );
        expect(
          allTargetsRecorded(_targets(), await dao.forVisit(visit.id)),
          isTrue,
        );
      },
    );
  });

  group('capture screen detection marking', () {
    testWidgets('offers only the Protocol version\'s declared Detection methods', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _startVisit(database);

      await _pumpCapture(
        tester,
        database: database,
        visit: visit,
        protocol: _document(
          methods: const [
            DetectionMethod(id: 'visual', label: 'Visual'),
            DetectionMethod(id: 'acoustic', label: 'Acoustic'),
          ],
        ),
      );

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byKey(_methodField()),
      );
      expect(
        dropdown.items!.map((item) => item.value).toList(),
        <String?>['visual', 'acoustic'],
      );
    });

    testWidgets(
      'a target Detection cannot be persisted until a method is chosen, then carries it',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visit = await _startVisit(database);

        await _pumpCapture(
          tester,
          database: database,
          visit: visit,
          protocol: _document(),
        );

        final before = tester.widget<SegmentedButton<bool>>(
          find.byKey(_control('Aves|Turdus|merula')),
        );
        expect(before.onSelectionChanged, isNull);

        await tester.tap(
          find.byKey(_detected('Aves|Turdus|merula')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(await DetectionDao(database).forVisit(visit.id), isEmpty);

        await _chooseMethod(tester, 'Visual');

        final after = tester.widget<SegmentedButton<bool>>(
          find.byKey(_control('Aves|Turdus|merula')),
        );
        expect(after.onSelectionChanged, isNotNull);

        await tester.tap(find.byKey(_detected('Aves|Turdus|merula')));
        await tester.pumpAndSettle();

        final stored = await DetectionDao(database).find(
          visit.id,
          'Aves|Turdus|merula',
        );
        expect(stored, isNotNull);
        expect(stored!.detected, isTrue);
        expect(stored.method, 'visual');
      },
    );

    testWidgets(
      'shows a two-state control and a distinct not-recorded state per target taxon',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visit = await _startVisit(database);

        await _pumpCapture(
          tester,
          database: database,
          visit: visit,
          protocol: _document(),
        );

        for (final target in _targets()) {
          expect(find.byKey(_detected(target.taxonRef)), findsOneWidget);
          expect(find.byKey(_notDetected(target.taxonRef)), findsOneWidget);
          expect(find.byKey(_notRecorded(target.taxonRef)), findsOneWidget);
        }
      },
    );

    testWidgets(
      'marking a target not detected stores a Detection with detected false',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visit = await _startVisit(database);

        await _pumpCapture(
          tester,
          database: database,
          visit: visit,
          protocol: _document(),
        );

        await _chooseMethod(tester, 'Visual');
        await tester.tap(find.byKey(_notDetected('Aves|Turdus|merula')));
        await tester.pumpAndSettle();

        final stored = await DetectionDao(database)
            .find(visit.id, 'Aves|Turdus|merula');
        expect(stored, isNotNull);
        expect(stored!.detected, isFalse);
        expect(find.byKey(_notRecorded('Aves|Turdus|merula')), findsNothing);
      },
    );

    testWidgets('marking every target taxon records a Detection for each', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _startVisit(database);

      await _pumpCapture(
        tester,
        database: database,
        visit: visit,
        protocol: _document(),
      );

      await _chooseMethod(tester, 'Visual');
      await tester.tap(find.byKey(_detected('Aves|Turdus|merula')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_notDetected('Aves|Erithacus|rubecula')));
      await tester.pumpAndSettle();

      final stored = await DetectionDao(database).forVisit(visit.id);
      expect(stored, hasLength(_targets().length));
      expect(
        stored
            .firstWhere(
              (detection) => detection.taxonRef == 'Aves|Turdus|merula',
            )
            .detected,
        isTrue,
      );
      expect(
        stored
            .firstWhere(
              (detection) => detection.taxonRef == 'Aves|Erithacus|rubecula',
            )
            .detected,
        isFalse,
      );
    });

    testWidgets(
      'reports incomplete while any target is unrecorded and complete once all are',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visit = await _startVisit(database);

        await _pumpCapture(
          tester,
          database: database,
          visit: visit,
          protocol: _document(),
        );

        expect(find.byKey(const Key('visit_incomplete')), findsOneWidget);
        expect(find.byKey(const Key('visit_complete')), findsNothing);

        await _chooseMethod(tester, 'Visual');
        await tester.tap(find.byKey(_detected('Aves|Turdus|merula')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(_notDetected('Aves|Erithacus|rubecula')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('visit_incomplete')), findsNothing);
        expect(find.byKey(const Key('visit_complete')), findsOneWidget);
      },
    );

    testWidgets('brings the next unrecorded target into view in one tap', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await _startVisit(database);

      await _pumpCapture(
        tester,
        database: database,
        visit: visit,
        protocol: _document(),
      );

      await _chooseMethod(tester, 'Visual');
      expect(find.byKey(_active('Aves|Turdus|merula')), findsNothing);

      await tester.tap(find.byKey(const Key('detection_next_unrecorded')));
      await tester.pumpAndSettle();
      expect(find.byKey(_active('Aves|Turdus|merula')), findsOneWidget);

      await tester.tap(find.byKey(_detected('Aves|Turdus|merula')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detection_next_unrecorded')));
      await tester.pumpAndSettle();
      expect(find.byKey(_active('Aves|Erithacus|rubecula')), findsOneWidget);
    });
  });

  group('migration', () {
    test(
      'migrates a version 11 client schema to version 13 adding method and count',
      () async {
        final database = AppDatabase(
          NativeDatabase.memory(
            setup: (raw) {
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
                "VALUES ('visit-1', 'site-1', 'sp-1', 'pv-1', 'inProgress', 1767225600);",
              );
              raw.execute(
                "INSERT INTO detections (visit_id, taxon_ref, detected, opportunistic) "
                "VALUES ('visit-1', 'Aves|Turdus|merula', 1, 0);",
              );
              raw.execute('PRAGMA user_version = 11');
            },
          ),
        );
        addTearDown(database.close);

        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 13);

        final columns = await database
            .customSelect('PRAGMA table_info(detections)')
            .get();
        expect(
          columns.map((row) => row.data['name']),
          containsAll(<String>['method', 'count']),
        );

        final dao = DetectionDao(database);
        final legacy = await dao.forVisit('visit-1');
        expect(legacy, hasLength(1));
        expect(legacy.single.method, isNull);
        expect(legacy.single.count, isNull);

        await dao.record(
          Detection(
            visitId: 'visit-1',
            taxonRef: 'Aves|Erithacus|rubecula',
            detected: true,
            method: 'visual',
            count: 2,
          ),
        );
        final stored = await dao.find('visit-1', 'Aves|Erithacus|rubecula');
        expect(stored!.method, 'visual');
        expect(stored.count, 2);
      },
    );

    test(
      'migrates a version 4 client schema to version 13 forward-only',
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
              raw.execute(
                "INSERT INTO visits (id, site_id, survey_period_id, protocol_version_id, state, effort_started_at) "
                "VALUES ('visit-1', 'site-1', 'survey-period-1', 'protocol-version-1', 'inProgress', 1767225600);",
              );
              raw.execute('PRAGMA user_version = 4');
            },
          ),
        );
        addTearDown(database.close);

        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 13);

        final tables = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'detections'",
            )
            .get();
        expect(tables, hasLength(1));

        final dao = DetectionDao(database);
        await dao.record(
          const Detection(
            visitId: 'visit-1',
            taxonRef: 'Aves|Turdus|merula',
            detected: false,
            method: 'visual',
          ),
        );
        expect((await dao.forVisit('visit-1')).single.detected, isFalse);
      },
    );
  });
}
