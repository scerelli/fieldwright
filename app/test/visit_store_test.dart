import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/features/visits/visits_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

final _uuidV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Site _site() => Site(
  id: 'site-1',
  projectId: 'project-1',
  geometry: const PointGeometry(LatLng(45.0, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  test(
    'starting a Visit creates it in progress with a recorded effort start time',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final startedAt = DateTime.utc(2026, 5, 1, 8, 0);

      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
        now: startedAt,
      );

      expect(visit.state, VisitState.inProgress);
      expect(visit.effort.startedAt, startedAt);
      expect(visit.effort.endedAt, isNull);
      expect(visit.id, matches(_uuidV7));
    },
  );

  test(
    'a Visit references exactly one Site, Survey period and Protocol version',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final dao = VisitDao(database);

      final visit = await dao.startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );

      expect(visit.siteId, 'site-1');
      expect(visit.surveyPeriodId, 'survey-period-1');
      expect(visit.protocolVersionId, 'protocol-version-1');

      final loaded = await dao.findById(visit.id);
      expect(loaded, isNotNull);
      expect(loaded!.siteId, 'site-1');
      expect(loaded.surveyPeriodId, 'survey-period-1');
      expect(loaded.protocolVersionId, 'protocol-version-1');
    },
  );

  test('ending a Visit moves it to ended with an end time and rejects further in-progress changes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final dao = VisitDao(database);
    final startedAt = DateTime.utc(2026, 5, 1, 8, 0);
    final endedAt = DateTime.utc(2026, 5, 1, 9, 30);

    final visit = await dao.startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
      now: startedAt,
    );
    final ended = await dao.endVisit(visit, now: endedAt);

    expect(ended.state, VisitState.ended);
    expect(ended.effort.startedAt, startedAt);
    expect(ended.effort.endedAt, endedAt);

    final loaded = await dao.findById(visit.id);
    expect(loaded!.state, VisitState.ended);
    expect(loaded.effort.endedAt, endedAt);

    await expectLater(
      () => dao.save(loaded.copyWith(state: VisitState.inProgress)),
      throwsStateError,
    );

    final afterRejectedChange = await dao.findById(visit.id);
    expect(afterRejectedChange!.state, VisitState.ended);
    expect(afterRejectedChange.effort.endedAt, endedAt);
  });

  test(
    'a submitted Visit is immutable and rejects further in-progress changes '
    '(INV-001)',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final dao = VisitDao(database);
      final visit = await dao.startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );
      final ended = await dao.endVisit(visit);
      final submitted = await dao.markSubmitted(ended.id);
      expect(submitted.state, VisitState.submitted);

      await expectLater(() => dao.save(submitted), throwsStateError);
      await expectLater(
        () => dao.save(submitted.copyWith(state: VisitState.inProgress)),
        throwsStateError,
      );
      await expectLater(() => dao.endVisit(submitted), throwsStateError);

      final afterRejectedChanges = await dao.findById(submitted.id);
      expect(afterRejectedChanges!.state, VisitState.submitted);
      expect(afterRejectedChanges.effort.endedAt, isNotNull);
    },
  );

  test(
    'a started Visit is readable from the local store after the app restarts',
    () async {
      final directory = Directory.systemTemp.createTempSync('ibis_visit_store');
      addTearDown(() => directory.deleteSync(recursive: true));
      final path = '${directory.path}/ibis.sqlite';
      final startedAt = DateTime.utc(2026, 5, 1, 8, 0);

      var database = AppDatabase.open(path);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
        now: startedAt,
      );
      await database.close();

      database = AppDatabase.open(path);
      final loaded = await VisitDao(database).findById(visit.id);
      await database.close();

      expect(loaded, isNotNull);
      expect(loaded!.state, VisitState.inProgress);
      expect(loaded.effort.startedAt, startedAt);
      expect(loaded.siteId, 'site-1');
      expect(loaded.surveyPeriodId, 'survey-period-1');
      expect(loaded.protocolVersionId, 'protocol-version-1');
    },
  );

  test(
    'migrates a version 3 client schema to version 10 forward-only',
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
            raw.execute('PRAGMA user_version = 3');
          },
        ),
      );
      addTearDown(database.close);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data['user_version'], 15);

      final tables = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'visits'",
          )
          .get();
      expect(tables, hasLength(1));

      final outbox = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'outbox_entries'",
          )
          .get();
      expect(outbox, hasLength(1));

      final dao = VisitDao(database);
      final visit = await dao.startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );
      expect((await dao.findById(visit.id))!.state, VisitState.inProgress);
    },
  );

  testWidgets(
    'starting and ending a Visit from the Visits screen persists the lifecycle',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const VisitsScreen(
              projectId: 'project-1',
              surveyPeriodId: 'survey-period-1',
              protocolVersionId: 'protocol-version-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('start_visit_site-1')));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsOneWidget);
      final started = await VisitDao(database).all();
      expect(started, hasLength(1));
      expect(started.single.state, VisitState.inProgress);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('end_visit_${started.single.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('end_visit_confirm')));
      await tester.pumpAndSettle();

      final ended = await VisitDao(database).all();
      expect(ended.single.state, VisitState.ended);
      expect(ended.single.effort.endedAt, isNotNull);
    },
  );
}
