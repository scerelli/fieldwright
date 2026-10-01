import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/visits/detection.dart';
import 'package:ibis/features/visits/detection_list.dart';
import 'package:ibis/features/visits/taxon_reference.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/detection_dao.dart';
import 'package:ibis/store/visit_dao.dart';

List<TargetTaxon> _targets() => const <TargetTaxon>[
  TargetTaxon(taxonRef: 'Aves|Turdus|merula', label: 'Common blackbird'),
];

ProtocolDocument _document() => ProtocolDocument(
  protocolId: 'alpine-birds',
  version: 1,
  taxonomicScope: const TaxonomicScope(taxa: ['Aves']),
  detectionMethods: const [DetectionMethod(id: 'visual', label: 'Visual')],
  requiredEffortFields: const [SamplingEffortField.start],
  targetList: _targets(),
);

Future<void> _pumpList(
  WidgetTester tester, {
  required AppDatabase database,
  required String visitId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        taxonReferenceProvider.overrideWithValue(_reference),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DetectionList(protocol: _document(), visitId: visitId),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _chooseMethod(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('detection_method')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<String> _startVisitId(AppDatabase database) async {
  final visit = await VisitDao(database).startVisit(
    siteId: 'site-1',
    surveyPeriodId: 'sp-1',
    protocolVersionId: 'pv-1',
  );
  return visit.id;
}

const _blackbird = Taxon(name: 'Turdus merula', abbreviation: 'TURMER');
const _robin = Taxon(name: 'Erithacus rubecula', abbreviation: 'ERRUB');
const _chaffinch = Taxon(name: 'Fringilla coelebs', abbreviation: 'FRCOE');

final _reference = InMemoryTaxonReference([_blackbird, _robin, _chaffinch]);

void main() {
  group('TaxonReference', () {
    test('matches taxa by abbreviation, case-insensitively', () {
      final matches = _reference.search('turmer');

      expect(matches.map((taxon) => taxon.name), ['Turdus merula']);
    });

    test('matches every taxon whose abbreviation contains the query', () {
      final matches = _reference.search('ER');

      expect(matches.map((taxon) => taxon.abbreviation).toSet(), {
        'TURMER',
        'ERRUB',
      });
    });

    test('lists every taxon for an empty query', () {
      expect(_reference.search(''), hasLength(3));
      expect(_reference.search('   '), hasLength(3));
    });

    test('returns nothing when no abbreviation matches', () {
      expect(_reference.search('zzz'), isEmpty);
    });
  });

  group('opportunistic Detection', () {
    test('is presence-only: detected and flagged opportunistic', () {
      final detection = Detection.opportunistic(
        visitId: 'visit-1',
        taxonRef: 'Turdus merula',
      );

      expect(detection.detected, isTrue);
      expect(detection.opportunistic, isTrue);
      expect(detection.visitId, 'visit-1');
      expect(detection.taxonRef, 'Turdus merula');
    });

    test('has no not-detected state, even through copyWith', () {
      final detection = Detection.opportunistic(
        visitId: 'visit-1',
        taxonRef: 'Turdus merula',
      );

      expect(detection.copyWith(detected: false).detected, isTrue);
      expect(detection.copyWith(detected: false).opportunistic, isTrue);
    });

    test('a target Detection is not opportunistic by default', () {
      const detection = Detection(
        visitId: 'visit-1',
        taxonRef: 'Aves|Turdus|merula',
        detected: true,
      );

      expect(detection.opportunistic, isFalse);
    });

    test('never counts toward target completeness (INV-003)', () {
      final detections = <Detection>[
        Detection.opportunistic(
          visitId: 'visit-1',
          taxonRef: 'Aves|Turdus|merula',
        ),
      ];

      expect(unrecordedTargets(_targets(), detections), hasLength(1));
      expect(allTargetsRecorded(_targets(), detections), isFalse);
    });
  });

  group('opportunistic Detection equality', () {
    test('an opportunistic Detection differs from a target Detection', () {
      const target = Detection(
        visitId: 'visit-1',
        taxonRef: 'Turdus merula',
        detected: true,
      );
      final opportunistic = Detection.opportunistic(
        visitId: 'visit-1',
        taxonRef: 'Turdus merula',
      );

      expect(opportunistic, isNot(equals(target)));
    });
  });

  group('DetectionDao opportunistic', () {
    test(
      'stores an opportunistic Detection as present, never a non-detection',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visit = await VisitDao(database).startVisit(
          siteId: 'site-1',
          surveyPeriodId: 'sp-1',
          protocolVersionId: 'pv-1',
        );
        final dao = DetectionDao(database);

        await dao.record(
          Detection.opportunistic(
            visitId: visit.id,
            taxonRef: 'Turdus merula',
            method: 'visual',
          ),
        );

        final stored = await dao.forVisit(visit.id);
        expect(stored, hasLength(1));
        expect(stored.single.detected, isTrue);
        expect(stored.single.opportunistic, isTrue);
        expect(await dao.find(visit.id, 'Turdus merula'), isNotNull);
      },
    );

    test('stores an opportunistic Detection with the method that recorded it', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'sp-1',
        protocolVersionId: 'pv-1',
      );
      final dao = DetectionDao(database);

      await dao.record(
        Detection.opportunistic(
          visitId: visit.id,
          taxonRef: 'Turdus merula',
          method: 'visual',
        ),
      );

      final stored = (await dao.forVisit(visit.id)).single;
      expect(stored.detected, isTrue);
      expect(stored.opportunistic, isTrue);
      expect(stored.method, 'visual');
    });

    test('keeps a target Detection and an opportunistic one apart', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'sp-1',
        protocolVersionId: 'pv-1',
      );
      final dao = DetectionDao(database);

      await dao.record(
        Detection(
          visitId: visit.id,
          taxonRef: 'Aves|Turdus|merula',
          detected: false,
          method: 'visual',
        ),
      );
      await dao.record(
        Detection.opportunistic(
          visitId: visit.id,
          taxonRef: 'Turdus merula',
          method: 'visual',
        ),
      );

      final stored = await dao.forVisit(visit.id);
      expect(stored, hasLength(2));
      expect(
        stored.where((detection) => detection.opportunistic).single.taxonRef,
        'Turdus merula',
      );
    });
  });

  group('opportunistic search on the capture list', () {
    testWidgets(
      'typing an abbreviation and picking a taxon adds an opportunistic Detection (INV-003, UX-005)',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visitId = await _startVisitId(database);

        await _pumpList(tester, database: database, visitId: visitId);
        await _chooseMethod(tester, 'Visual');

        await tester.enterText(
          find.byKey(const Key('opportunistic_search_field')),
          'turmer',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('opportunistic_result_TURMER')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('opportunistic_result_ERRUB')),
          findsNothing,
        );

        await tester.tap(find.byKey(const Key('opportunistic_result_TURMER')));
        await tester.pumpAndSettle();

        final stored = await DetectionDao(database).forVisit(visitId);
        expect(stored, hasLength(1));
        expect(stored.single.taxonRef, 'Turdus merula');
        expect(stored.single.detected, isTrue);
        expect(stored.single.opportunistic, isTrue);
      },
    );

    testWidgets(
      'an opportunistic Detection carries the chosen method and stays presence-only (INV-003)',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visitId = await _startVisitId(database);

        await _pumpList(tester, database: database, visitId: visitId);
        await _chooseMethod(tester, 'Visual');

        await tester.enterText(
          find.byKey(const Key('opportunistic_search_field')),
          'turmer',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('opportunistic_result_TURMER')));
        await tester.pumpAndSettle();

        final stored = await DetectionDao(database).forVisit(visitId);
        expect(stored, hasLength(1));
        expect(stored.single.taxonRef, 'Turdus merula');
        expect(stored.single.detected, isTrue);
        expect(stored.single.opportunistic, isTrue);
        expect(stored.single.method, 'visual');
      },
    );

    testWidgets('free text alone never adds a taxon (UX-005)', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visitId = await _startVisitId(database);

      await _pumpList(tester, database: database, visitId: visitId);

      await tester.enterText(
        find.byKey(const Key('opportunistic_search_field')),
        'turmer',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(await DetectionDao(database).forVisit(visitId), isEmpty);
      expect(
        find.byKey(const Key('opportunistic_result_TURMER')),
        findsOneWidget,
      );
    });

    testWidgets(
      'an opportunistic Detection shows as present with no not-detected control (INV-003)',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visitId = await _startVisitId(database);
        await DetectionDao(database).record(
          Detection.opportunistic(
            visitId: visitId,
            taxonRef: 'Turdus merula',
            method: 'visual',
          ),
        );

        await _pumpList(tester, database: database, visitId: visitId);

        expect(
          find.byKey(const Key('opportunistic_entry_Turdus merula')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('detection_not_detected_Turdus merula')),
          findsNothing,
        );
      },
    );
  });

  group('client schema migration', () {
    test('migrates a version 5 schema to version 10 forward-only', () async {
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
  PRIMARY KEY (visit_id, taxon_ref)
);
''');
            raw.execute(
              "INSERT INTO visits (id, site_id, survey_period_id, protocol_version_id, state, effort_started_at) "
              "VALUES ('visit-1', 'site-1', 'sp-1', 'pv-1', 'inProgress', 1767225600);",
            );
            raw.execute(
              "INSERT INTO detections (visit_id, taxon_ref, detected) "
              "VALUES ('visit-1', 'Aves|Turdus|merula', 1);",
            );
            raw.execute('PRAGMA user_version = 5');
          },
        ),
      );
      addTearDown(database.close);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data['user_version'], 10);

      final stored = await DetectionDao(database).forVisit('visit-1');
      expect(stored, hasLength(1));
      expect(stored.single.detected, isTrue);
      expect(stored.single.opportunistic, isFalse);
    });
  });
}
