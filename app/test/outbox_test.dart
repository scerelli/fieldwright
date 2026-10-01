import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/auth/auth_provider.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/outbox/outbox.dart';
import 'package:ibis/outbox/sync_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/outbox_dao.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

final _uuidV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

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

ResponseBody jsonResponse(
  Object body, {
  int statusCode = 200,
  Map<String, List<String>> headers = const <String, List<String>>{},
}) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    ...headers,
  },
);

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

/// A production-like scope: the real `outboxProvider` wiring, with only the
/// HTTP transport faked.
ProviderContainer _container(AppDatabase database, FakeHttpAdapter adapter) {
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      syncClientProvider.overrideWithValue(
        _syncClient(adapter, _authWith(adapter)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// A production-like scope with the real auth wiring: the same [AuthClient]
/// backs the sync client, so the auth cookie captured at sign-in is what the sync
/// API sees.
ProviderContainer _authContainer(
  AppDatabase database,
  FakeHttpAdapter adapter,
) {
  final auth = _authWith(adapter);
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      authClientProvider.overrideWithValue(auth),
      syncClientProvider.overrideWithValue(
        SyncClient(
          baseUrl: 'http://test.local',
          auth: auth,
          dio: _dioWith(adapter),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<ResponseBody> _signIn(RequestOptions options) => Future.value(
  jsonResponse(
    <String, dynamic>{
      'user': <String, dynamic>{
        'id': 'u1',
        'email': 'ada@example.com',
        'name': 'Ada Lovelace',
      },
    },
    headers: <String, List<String>>{
      'set-cookie': <String>[
        'better-auth.session_token=token-123; Path=/', // glossary:allow Better Auth session cookie, not the Visit
      ],
    },
  ),
);

/// An idempotent sync server: the first submission of an id stores it, a
/// replay of the same id returns the already-stored Visit.
FakeHttpAdapter acceptingAdapter({Set<String>? created}) {
  final stored = created ?? <String>{};
  return FakeHttpAdapter((options) async {
    if (options.path == '/api/auth/sign-in/email') return _signIn(options);
    if (options.path == SyncClient.submitPath) {
      final body = (options.data! as Map).cast<String, dynamic>();
      final id = body['id'] as String;
      final replay = stored.contains(id);
      stored.add(id);
      return jsonResponse(<String, dynamic>{
        'id': id,
      }, statusCode: replay ? 200 : 201);
    }
    return jsonResponse(<String, dynamic>{
      'message': 'not found',
    }, statusCode: 404);
  });
}

/// Rejects every submission the way the server rejects invalid data.
FakeHttpAdapter rejectingAdapter() => FakeHttpAdapter((options) async {
  if (options.path == '/api/auth/sign-in/email') return _signIn(options);
  return jsonResponse(<String, dynamic>{
    'message': 'invalid submission',
  }, statusCode: 400);
});

/// An authenticated sync server: signs in by setting the auth cookie, then
/// answers a submission 401 until the request carries that cookie.
FakeHttpAdapter authAdapter() => FakeHttpAdapter((options) async {
  if (options.path == '/api/auth/sign-in/email') return _signIn(options);
  if (options.headers['cookie'] == null) {
    return jsonResponse(<String, dynamic>{
      'message': 'unauthorized',
    }, statusCode: 401);
  }
  final body = (options.data! as Map).cast<String, dynamic>();
  return jsonResponse(<String, dynamic>{'id': body['id']}, statusCode: 201);
});

/// Loses the connection for the first [failures] attempts, then accepts.
FakeHttpAdapter flakyAdapter({required int failures}) {
  var attempts = 0;
  return FakeHttpAdapter((options) async {
    attempts += 1;
    if (attempts <= failures) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'offline',
      );
    }
    final body = (options.data! as Map).cast<String, dynamic>();
    return jsonResponse(<String, dynamic>{'id': body['id']}, statusCode: 201);
  });
}

int _submitCalls(FakeHttpAdapter adapter) => adapter.requests
    .where((request) => request.path == SyncClient.submitPath)
    .length;

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
          overrides: [
            databaseProvider.overrideWithValue(database),
            // Queuing only: the delivery engine is unwired here so the Visit
            // stays queued (the wired path is covered below).
            outboxProvider.overrideWithValue(Outbox(OutboxDao(database))),
          ],
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

  group('SyncClient', () {
    test('re-sending a Visit sends the same UUIDv7 id each time, so the '
        'idempotent server stores one Visit', () async {
      final stored = <String>{};
      final adapter = acceptingAdapter(created: stored);
      final client = _syncClient(adapter, _authWith(adapter));
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final visit = await _endedVisit(database);

      final first = await client.submit(visit, projectId: 'project-1');
      final second = await client.submit(visit, projectId: 'project-1');

      expect(first, SubmitResult.delivered);
      expect(second, SubmitResult.delivered);
      final submissions = adapter.requests
          .where((request) => request.path == SyncClient.submitPath)
          .toList();
      expect(submissions, hasLength(2));
      expect(submissions.first.data['id'], visit.id);
      expect(submissions.last.data['id'], visit.id);
      expect(visit.id, matches(_uuidV7));
      expect(stored, hasLength(1));
    });

    test(
      'a submission targets the versioned sync API with the auth cookie',
      () async {
        final adapter = acceptingAdapter();
        final auth = _authWith(adapter);
        await auth.signIn(email: 'ada@example.com', password: 'correct');
        final client = _syncClient(adapter, auth);
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await SiteDao(database).save(_site());
        final visit = await _endedVisit(database);

        await client.submit(visit, projectId: 'project-1');

        final submission = adapter.requests.firstWhere(
          (request) => request.path == SyncClient.submitPath,
        );
        expect(submission.method, 'POST');
        expect(submission.headers['cookie'], contains('token-123'));
        expect(submission.data['projectId'], 'project-1');
        expect(submission.data['siteId'], 'site-1');
        expect(submission.data['surveyPeriodId'], 'survey-period-1');
        expect(submission.data['protocolVersionId'], 'protocol-version-1');
        expect(submission.data['startedAt'], isA<String>());
        expect(submission.data['submittedAt'], isA<String>());
      },
    );

    test('a 4xx response is a rejection', () async {
      final adapter = rejectingAdapter();
      final client = _syncClient(adapter, _authWith(adapter));
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final visit = await _endedVisit(database);

      expect(
        await client.submit(visit, projectId: 'project-1'),
        SubmitResult.rejected,
      );
    });

    test(
      'a 401 or 403 from the sync API is retryable, not a rejection',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await SiteDao(database).save(_site());
        final visit = await _endedVisit(database);

        for (final status in <int>[401, 403]) {
          final adapter = FakeHttpAdapter(
            (options) async => jsonResponse(<String, dynamic>{
              'message': 'unauthorized',
            }, statusCode: status),
          );
          await expectLater(
            () => _syncClient(
              adapter,
              _authWith(adapter),
            ).submit(visit, projectId: 'project-1'),
            throwsA(isA<SubmissionUnavailable>()),
          );
        }
      },
    );

    test(
      'a server error or a lost connection is retryable, not a rejection',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await SiteDao(database).save(_site());
        final visit = await _endedVisit(database);

        final serverError = FakeHttpAdapter(
          (options) async => jsonResponse(<String, dynamic>{
            'message': 'boom',
          }, statusCode: 500),
        );
        await expectLater(
          () => _syncClient(
            serverError,
            _authWith(serverError),
          ).submit(visit, projectId: 'project-1'),
          throwsA(isA<SubmissionUnavailable>()),
        );

        final offline = FakeHttpAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'offline',
          );
        });
        await expectLater(
          () => _syncClient(
            offline,
            _authWith(offline),
          ).submit(visit, projectId: 'project-1'),
          throwsA(isA<SubmissionUnavailable>()),
        );
      },
    );
  });

  group('Outbox delivery', () {
    test('a queued Visit uploads, becomes synced, and its lifecycle becomes '
        'submitted', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final visitDao = VisitDao(database);
      final ended = await _endedVisit(database);
      final adapter = acceptingAdapter();
      final outbox = _outbox(
        database,
        _syncClient(adapter, _authWith(adapter)),
      );

      await OutboxDao(database).enqueue(ended.id);
      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.queued);

      final result = await outbox.deliver(ended);

      expect(result, SyncState.synced);
      expect(_submitCalls(adapter), 1);
      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.synced);
      expect((await visitDao.findById(ended.id))!.state, VisitState.submitted);
    });

    test('a transient failure is retried with increasing backoff until the '
        'Visit is delivered', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final visitDao = VisitDao(database);
      final ended = await _endedVisit(database);
      final adapter = flakyAdapter(failures: 2);
      final outbox = _outbox(
        database,
        _syncClient(adapter, _authWith(adapter)),
      );
      final sleeps = <Duration>[];

      final result = await outbox.deliver(
        ended,
        retry: const RetryPolicy(
          maxAttempts: 3,
          initialBackoff: Duration(seconds: 2),
        ),
        sleep: (duration) async => sleeps.add(duration),
      );

      expect(result, SyncState.synced);
      expect(_submitCalls(adapter), 3);
      expect(sleeps, const [Duration(seconds: 2), Duration(seconds: 4)]);
      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.synced);
      expect((await visitDao.findById(ended.id))!.state, VisitState.submitted);
    });

    test(
      'retries exhausted marks the Visit failed but does not drop it',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await SiteDao(database).save(_site());
        final visitDao = VisitDao(database);
        final ended = await _endedVisit(database);
        final adapter = flakyAdapter(failures: 100);
        final outbox = _outbox(
          database,
          _syncClient(adapter, _authWith(adapter)),
        );

        final result = await outbox.deliver(
          ended,
          retry: const RetryPolicy(
            maxAttempts: 3,
            initialBackoff: Duration.zero,
          ),
          sleep: (duration) async {},
        );

        expect(result, SyncState.failed);
        expect(_submitCalls(adapter), 3);
        expect(
          await OutboxDao(database).syncStateOf(ended.id),
          SyncState.failed,
        );
        expect((await visitDao.findById(ended.id))!.state, VisitState.ended);
      },
    );

    test(
      'a rejected submission is marked failed and remains retryable',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await SiteDao(database).save(_site());
        final visitDao = VisitDao(database);
        final ended = await _endedVisit(database);
        final rejecting = rejectingAdapter();
        final outbox = _outbox(
          database,
          _syncClient(rejecting, _authWith(rejecting)),
        );

        await OutboxDao(database).enqueue(ended.id);
        expect(await outbox.deliver(ended), SyncState.failed);
        expect(
          await OutboxDao(database).syncStateOf(ended.id),
          SyncState.failed,
        );
        expect((await visitDao.findById(ended.id))!.state, VisitState.ended);

        final accepting = acceptingAdapter();
        final retry = _outbox(
          database,
          _syncClient(accepting, _authWith(accepting)),
        );
        expect(await retry.deliver(ended), SyncState.synced);
        expect(
          (await visitDao.findById(ended.id))!.state,
          VisitState.submitted,
        );
      },
    );

    test(
      'a Visit stranded syncing by a crash is recovered and delivered',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await SiteDao(database).save(_site());
        final visitDao = VisitDao(database);
        final ended = await _endedVisit(database);
        final dao = OutboxDao(database);
        await dao.enqueue(ended.id);
        await dao.setSyncState(ended.id, SyncState.syncing);
        final adapter = acceptingAdapter();
        final outbox = _outbox(
          database,
          _syncClient(adapter, _authWith(adapter)),
        );

        await outbox.flush();

        expect(await dao.syncStateOf(ended.id), SyncState.synced);
        expect(
          (await visitDao.findById(ended.id))!.state,
          VisitState.submitted,
        );
      },
    );

    test('flush delivers every queued and failed submission', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final visitDao = VisitDao(database);
      final first = await _endedVisit(database);
      final second = await _endedVisit(database);
      final adapter = acceptingAdapter();
      final outbox = _outbox(
        database,
        _syncClient(adapter, _authWith(adapter)),
      );

      await OutboxDao(database).enqueue(first.id);
      await OutboxDao(database).enqueue(second.id);
      await OutboxDao(database).setSyncState(second.id, SyncState.failed);

      await outbox.flush();

      expect(await OutboxDao(database).syncStateOf(first.id), SyncState.synced);
      expect(
        await OutboxDao(database).syncStateOf(second.id),
        SyncState.synced,
      );
      expect(_submitCalls(adapter), 2);
      expect((await visitDao.findById(first.id))!.state, VisitState.submitted);
      expect((await visitDao.findById(second.id))!.state, VisitState.submitted);
    });

    test('a Visit whose Site is missing does not block a later queued Visit',
        () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final visitDao = VisitDao(database);
      final orphan = await visitDao.startVisit(
        siteId: 'site-missing',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );
      final orphanEnded = await visitDao.endVisit(orphan);
      final healthy = await _endedVisit(database);
      final adapter = acceptingAdapter();
      final outbox = _outbox(
        database,
        _syncClient(adapter, _authWith(adapter)),
      );
      final dao = OutboxDao(database);
      await dao.enqueue(
        orphanEnded.id,
        queuedAt: DateTime.utc(2026, 1, 1),
      );
      await dao.enqueue(healthy.id, queuedAt: DateTime.utc(2026, 1, 2));

      await outbox.flush();

      expect(
        (await visitDao.findById(healthy.id))!.state,
        VisitState.submitted,
      );
      expect(await dao.syncStateOf(healthy.id), SyncState.synced);
      expect(await dao.syncStateOf(orphanEnded.id), SyncState.failed);
      expect(_submitCalls(adapter), 1);
    });

    test('delivering a Visit whose Site is missing is a local error', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visitDao = VisitDao(database);
      final orphan = await visitDao.startVisit(
        siteId: 'site-missing',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );
      final ended = await visitDao.endVisit(orphan);
      final adapter = acceptingAdapter();
      final outbox = _outbox(
        database,
        _syncClient(adapter, _authWith(adapter)),
      );

      await expectLater(() => outbox.deliver(ended), throwsStateError);
      expect(_submitCalls(adapter), 0);
    });

    test('delivering an in-progress Visit is rejected', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
      );
      final adapter = acceptingAdapter();
      final outbox = _outbox(
        database,
        _syncClient(adapter, _authWith(adapter)),
      );

      await expectLater(() => outbox.deliver(visit), throwsStateError);
      expect(_submitCalls(adapter), 0);
    });
  });

  group('production wiring', () {
    test('queuing a Visit triggers delivery without a manual flush', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final adapter = acceptingAdapter();
      final container = _container(database, adapter);
      final ended = await _endedVisit(database);

      await container.read(outboxProvider).submit(ended);
      await pumpEventQueue();

      expect(_submitCalls(adapter), 1);
      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.synced);
      expect(
        (await VisitDao(database).findById(ended.id))!.state,
        VisitState.submitted,
      );
    });

    test(
      'a Visit queued on a previous launch is delivered at app start',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await SiteDao(database).save(_site());
        final ended = await _endedVisit(database);
        await OutboxDao(database).enqueue(ended.id);
        final adapter = acceptingAdapter();
        final container = _container(database, adapter);

        await container.read(outboxStartupProvider.future);

        expect(
          await OutboxDao(database).syncStateOf(ended.id),
          SyncState.synced,
        );
        expect(
          (await VisitDao(database).findById(ended.id))!.state,
          VisitState.submitted,
        );
      },
    );

    test('an unauthenticated flush leaves the Visit queued, and auth delivers '
        'it', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final ended = await _endedVisit(database);
      await OutboxDao(database).enqueue(ended.id);
      final adapter = authAdapter();
      final container = _authContainer(database, adapter);
      container.read(outboxAuthFlushProvider);

      await container.read(outboxStartupProvider.future);

      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.queued);
      expect(
        (await VisitDao(database).findById(ended.id))!.state,
        VisitState.ended,
      );

      await container
          .read(authProvider.notifier)
          .signIn(email: 'ada@example.com', password: 'correct');
      await pumpEventQueue();

      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.synced);
      expect(
        (await VisitDao(database).findById(ended.id))!.state,
        VisitState.submitted,
      );
    });

    test('a failed flush at app start is error-safe and keeps the Visit '
        'retryable', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final ended = await _endedVisit(database);
      await OutboxDao(database).enqueue(ended.id);
      final rejecting = _container(database, rejectingAdapter());

      await rejecting.read(outboxStartupProvider.future);

      expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.failed);
      expect(
        (await VisitDao(database).findById(ended.id))!.state,
        VisitState.ended,
      );

      final accepting = _container(database, acceptingAdapter());
      await accepting.read(outboxStartupProvider.future);
      expect(
        (await VisitDao(database).findById(ended.id))!.state,
        VisitState.submitted,
      );
    });
  });
}
