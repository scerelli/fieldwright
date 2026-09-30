import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/outbox/outbox.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/outbox_dao.dart';
import 'package:ibis/store/visit_dao.dart';

void main() {
  test('submitting an ended Visit with no connectivity persists it as queued '
      'rather than losing it', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final visitDao = VisitDao(database);
    final outbox = Outbox(OutboxDao(database));

    final visit = await visitDao.startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
    );
    final ended = await visitDao.endVisit(visit);
    await outbox.submit(ended);

    expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.queued);
    expect(await visitDao.findById(ended.id), isNotNull);
  });

  test('an in-progress Visit cannot be submitted', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final outbox = Outbox(OutboxDao(database));

    final visit = await VisitDao(database).startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
    );

    await expectLater(() => outbox.submit(visit), throwsStateError);
    expect(await OutboxDao(database).syncStateOf(visit.id), isNull);
  });

  testWidgets(
    'submitting an ended Visit from the capture screen queues it for delivery',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visitDao = VisitDao(database);
      final visit = await visitDao.startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );
      final ended = await visitDao.endVisit(visit);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CaptureScreen(visit: ended),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_visit')));
      await tester.pumpAndSettle();

      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.queued);
      expect(await visitDao.findById(ended.id), isNotNull);
    },
  );

  test('a submitted Visit\'s sync state is stored as one of queued, syncing, '
      'synced or failed, and is readable from the local store', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final visit = await VisitDao(database).startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
    );
    final dao = OutboxDao(database);
    await dao.enqueue(visit.id);

    expect(SyncState.values, const [
      SyncState.queued,
      SyncState.syncing,
      SyncState.synced,
      SyncState.failed,
    ]);
    for (final state in SyncState.values) {
      await dao.setSyncState(visit.id, state);
      expect(await dao.syncStateOf(visit.id), state);
    }
  });

  test('a queued submission survives an app relaunch', () async {
    final directory = Directory.systemTemp.createTempSync('ibis_outbox');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/ibis.sqlite';

    var database = AppDatabase.open(path);
    final visit = await VisitDao(database).startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
    );
    await OutboxDao(database).enqueue(visit.id);
    await database.close();

    database = AppDatabase.open(path);
    final state = await OutboxDao(database).syncStateOf(visit.id);
    await database.close();

    expect(state, SyncState.queued);
  });
}
