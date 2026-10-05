import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/detection.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/outbox/outbox.dart';
import 'package:ibis/outbox/sync_client.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/detection_dao.dart';
import 'package:ibis/store/outbox_dao.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

/// Fakes the HTTP layer: no request ever leaves the process.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._handle);

  final Future<ResponseBody> Function(RequestOptions options) _handle;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _handle(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

Dio _dioWith(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return dio;
}

AuthClient _authWith(FakeHttpAdapter adapter) =>
    AuthClient(baseUrl: 'http://test.local', dio: _dioWith(adapter));

SyncClient _syncClient(FakeHttpAdapter adapter, AuthClient auth) => SyncClient(
  baseUrl: 'http://test.local',
  auth: auth,
  dio: _dioWith(adapter),
);

Outbox _outbox(AppDatabase database, SyncClient client) => Outbox(
  OutboxDao(database),
  client: client,
  visits: VisitDao(database),
  sites: SiteDao(database),
);

FakeHttpAdapter _acceptingAdapter() => FakeHttpAdapter((options) async {
  final body = (options.data! as Map).cast<String, dynamic>();
  return _jsonResponse(<String, dynamic>{'id': body['id']}, statusCode: 201);
});

int _submitCalls(FakeHttpAdapter adapter) => adapter.requests
    .where((request) => request.path == SyncClient.submitPath)
    .length;

Site _site() => Site(
  id: 'site-1',
  projectId: 'project-1',
  geometry: const PointGeometry(LatLng(45.0, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

Future<Visit> _endedVisit(AppDatabase database) async {
  final dao = VisitDao(database);
  final visit = await dao.startVisit(
    siteId: 'site-1',
    surveyPeriodId: 'survey-period-1',
    protocolVersionId: 'protocol-version-1',
  );
  return dao.endVisit(visit);
}

Future<void> _insertProtocolVersion(
  AppDatabase database,
  String id, {
  required List<SamplingEffortField> required,
}) async {
  final document = ProtocolDocument(
    protocolId: 'protocol-1',
    version: 1,
    taxonomicScope: const TaxonomicScope(taxa: <String>[]),
    detectionMethods: const <DetectionMethod>[],
    requiredEffortFields: required,
  );
  await database
      .into(database.protocolVersions)
      .insert(
        ProtocolVersionsCompanion.insert(
          id: id,
          projectId: 'project-1',
          protocolId: 'protocol-1',
          version: 1,
          document: jsonEncode(document.toJson()),
        ),
      );
}

Widget _host(AppDatabase database, Widget child) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  group('buildSubmitPayload', () {
    test('emits a non-null value under every required wire field', () {
      final visit = Visit(
        id: 'visit-1',
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
        state: VisitState.ended,
        effort: SamplingEffort(
          startedAt: DateTime.utc(2026, 1, 1, 10),
          endedAt: DateTime.utc(2026, 1, 1, 10, 5),
          observers: const <String>['Ada'],
        ),
      );

      final payload = buildSubmitPayload(
        SubmissionAggregate(visit: visit),
        projectId: 'project-1',
        requiredEffortFields: SamplingEffortField.values,
        detectionMethods: const <String>['visual', 'acoustic'],
        submittedAt: DateTime.utc(2026, 1, 1, 11),
      );

      final effort = payload['effort'] as Map<String, dynamic>;
      for (final field in SamplingEffortField.values) {
        expect(effort[field.wireValue], isNotNull, reason: field.wireValue);
      }
      expect(effort['start'], visit.effort.startedAt.toUtc().toIso8601String());
      expect(effort['duration'], 300);
      expect(effort['observers'], const <String>['Ada']);
      expect(effort['detectionMethods'], const <String>['visual', 'acoustic']);
    });

    test('emits only the wire fields the Protocol version requires', () {
      final visit = Visit(
        id: 'visit-1',
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
        state: VisitState.ended,
        effort: SamplingEffort(
          startedAt: DateTime.utc(2026, 1, 1, 10),
          endedAt: DateTime.utc(2026, 1, 1, 10, 5),
        ),
      );

      final payload = buildSubmitPayload(
        SubmissionAggregate(visit: visit),
        projectId: 'project-1',
        requiredEffortFields: const <SamplingEffortField>[
          SamplingEffortField.duration,
        ],
        detectionMethods: const <String>['visual'],
      );

      final effort = payload['effort'] as Map<String, dynamic>;
      expect(effort.keys, <String>['duration']);
      expect(effort['duration'], 300);
    });
  });

  group('VisitDao sampling-effort reads', () {
    test('detectionMethodsFor is the distinct set of methods its Detections '
        'record', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );
      final detections = DetectionDao(database);
      await detections.record(
        Detection(
          visitId: visit.id,
          taxonRef: 't1',
          detected: true,
          method: 'visual',
        ),
      );
      await detections.record(
        Detection(
          visitId: visit.id,
          taxonRef: 't2',
          detected: false,
          method: 'visual',
        ),
      );
      await detections.record(
        Detection(
          visitId: visit.id,
          taxonRef: 't3',
          detected: true,
          method: 'acoustic',
        ),
      );

      expect(await VisitDao(database).detectionMethodsFor(visit.id), const [
        'acoustic',
        'visual',
      ]);
    });

    test(
      'requiredEffortFieldsFor reads the Visit Protocol version document',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await _insertProtocolVersion(
          database,
          'protocol-version-1',
          required: const <SamplingEffortField>[
            SamplingEffortField.observers,
            SamplingEffortField.detectionMethods,
          ],
        );
        final visit = await _endedVisit(database);

        expect(await VisitDao(database).requiredEffortFieldsFor(visit), const [
          SamplingEffortField.observers,
          SamplingEffortField.detectionMethods,
        ]);
      },
    );
  });

  group('observers', () {
    test('recording observers persists them across a reload', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );

      await VisitDao(database)
          .recordObservers(visit.id, const <String>['Ada', 'Grace']);

      final reloaded = await VisitDao(database).findById(visit.id);
      expect(reloaded!.effort.observers, const <String>['Ada', 'Grace']);
    });

    testWidgets('the visit screen records observers and they reload', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final ended = await _endedVisit(database);

      await tester.pumpWidget(_host(database, CaptureScreen(visit: ended)));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('observers_field')),
        'Ada, Grace',
      );
      await tester.tap(find.byKey(const Key('observers_save')));
      await tester.pumpAndSettle();

      expect(
        (await VisitDao(database).findById(ended.id))!.effort.observers,
        const <String>['Ada', 'Grace'],
      );

      await tester.pumpWidget(_host(database, CaptureScreen(visit: ended)));
      await tester.pumpAndSettle();
      expect(find.text('Ada, Grace'), findsOneWidget);
    });
  });

  group('Outbox sampling-effort gate', () {
    test('an observers-required Visit is not delivered until they are '
        'recorded, and stays retryable', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      await _insertProtocolVersion(
        database,
        'protocol-version-1',
        required: const <SamplingEffortField>[SamplingEffortField.observers],
      );
      final visitDao = VisitDao(database);
      final ended = await _endedVisit(database);
      final adapter = _acceptingAdapter();
      final outbox = _outbox(
        database,
        _syncClient(adapter, _authWith(adapter)),
      );

      final first = await outbox.deliver(ended);

      expect(first, SyncState.failed);
      expect(_submitCalls(adapter), 0);
      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.failed);
      expect((await visitDao.findById(ended.id))!.state, VisitState.ended);

      await visitDao.recordObservers(ended.id, const <String>['Ada']);
      final reloaded = (await visitDao.findById(ended.id))!;
      final second = await outbox.deliver(reloaded);

      expect(second, SyncState.synced);
      expect(_submitCalls(adapter), 1);
      expect((await visitDao.findById(ended.id))!.state, VisitState.submitted);
      final effort = (adapter.requests.last.data as Map)['effort'] as Map;
      expect(effort['observers'], const <String>['Ada']);
    });
  });

  group('migration', () {
    test('migrates a version 13 client schema to version 14 adding effort '
        'observers', () async {
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
            raw.execute(
              "INSERT INTO visits (id, site_id, survey_period_id, protocol_version_id, state, effort_started_at) "
              "VALUES ('visit-1', 'site-1', 'survey-period-1', 'protocol-version-1', 'inProgress', 1767225600);",
            );
            raw.execute('PRAGMA user_version = 13');
          },
        ),
      );
      addTearDown(database.close);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data['user_version'], 18);

      final columns = await database
          .customSelect('PRAGMA table_info(visits)')
          .get();
      expect(
        columns.map((row) => row.data['name']),
        contains('effort_observers'),
      );

      final stored = await VisitDao(database).findById('visit-1');
      expect(stored!.effort.observers, isEmpty);
    });
  });
}
