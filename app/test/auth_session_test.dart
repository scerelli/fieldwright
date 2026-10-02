import 'dart:async';
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
import 'package:ibis/features/account/account_screen.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/outbox/outbox.dart';
import 'package:ibis/outbox/sync_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/auth_session_dao.dart'; // glossary:allow auth session
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/outbox_dao.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

/// The person a persisted sign-in belongs to. // glossary:allow auth session
const Person _ada = Person(
  id: 'u1',
  email: 'ada@example.com',
  name: 'Ada Lovelace',
);

const String _persistedCookie = 'ibis.auth.token=persisted-cookie'; // glossary:allow Better Auth session cookie, not the Visit

Map<String, dynamic> _adaJson() => <String, dynamic>{
  'id': 'u1',
  'email': 'ada@example.com',
  'name': 'Ada Lovelace',
};

/// Fakes the HTTP layer: no request ever leaves the process.
class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this._handle);

  final Future<ResponseBody> Function(RequestOptions options) _handle;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _handle(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(
  Object? body, {
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

Dio _dio(_FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return dio;
}

/// A production-like scope: the real `authProvider`/`outbox` wiring over the
/// pinned dio client, with only the HTTP transport faked.
ProviderContainer _container(
  AppDatabase database,
  _FakeHttpAdapter adapter, {
  Duration requestTimeout = AuthClient.defaultRequestTimeout,
}) {
  final auth = AuthClient(
    baseUrl: 'http://test.local',
    dio: _dio(adapter),
    requestTimeout: requestTimeout,
  );
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      authClientProvider.overrideWithValue(auth),
      syncClientProvider.overrideWithValue(
        SyncClient(
          baseUrl: 'http://test.local',
          auth: auth,
          dio: _dio(adapter),
        ),
      ),
    ],
  );
}

/// A Better Auth server that sets the auth cookie at sign-in, confirms it at
/// `get-session`, and only accepts a submission that carries it. // glossary:allow Better Auth auth session, not the domain Visit
_FakeHttpAdapter _validatingAdapter() => _FakeHttpAdapter((options) async {
  if (options.path == '/api/auth/sign-in/email') {
    return _json(
      <String, dynamic>{'user': _adaJson()},
      headers: <String, List<String>>{
        'set-cookie': <String>[
          '$_persistedCookie; Path=/; HttpOnly', // glossary:allow Better Auth session cookie, not the Visit
        ],
      },
    );
  }
  if (options.path == '/api/auth/get-session') { // glossary:allow Better Auth auth session, not the domain Visit
    if (options.headers['cookie'] == _persistedCookie) {
      return _json(<String, dynamic>{
        'session': <String, dynamic>{'id': 'session-1'}, // glossary:allow Better Auth auth session, not the domain Visit
        'user': _adaJson(),
      });
    }
    return _json(<String, dynamic>{'message': 'unauthorized'}, statusCode: 401);
  }
  if (options.path == SyncClient.submitPath) {
    if (options.headers['cookie'] == null) {
      return _json(<String, dynamic>{
        'message': 'unauthorized',
      }, statusCode: 401);
    }
    final body = (options.data! as Map).cast<String, dynamic>();
    return _json(<String, dynamic>{'id': body['id']}, statusCode: 201);
  }
  return _json(<String, dynamic>{'message': 'not found'}, statusCode: 404);
});

/// A server that refuses the persisted auth cookie.
_FakeHttpAdapter _rejectingAdapter() => _FakeHttpAdapter((options) async {
  if (options.path == '/api/auth/get-session') { // glossary:allow Better Auth auth session, not the domain Visit
    return _json(<String, dynamic>{'message': 'unauthorized'}, statusCode: 401);
  }
  return _json(<String, dynamic>{'message': 'not found'}, statusCode: 404);
});

/// A server that cannot be reached at all.
_FakeHttpAdapter _offlineAdapter() => _FakeHttpAdapter((options) async {
  throw DioException(
    requestOptions: options,
    type: DioExceptionType.connectionError,
    error: 'offline',
  );
});

/// A server that accepts the connection but never answers, so any request
/// against it hangs until a timeout bounds it.
_FakeHttpAdapter _hangingAdapter() =>
    _FakeHttpAdapter((options) => Completer<ResponseBody>().future);

/// A server that answers `get-session` with a transient 5xx fault. // glossary:allow Better Auth auth session, not the domain Visit
_FakeHttpAdapter _serverFaultAdapter() => _FakeHttpAdapter((options) async {
  if (options.path == '/api/auth/get-session') { // glossary:allow Better Auth auth session, not the domain Visit
    return _json(<String, dynamic>{'message': 'boom'}, statusCode: 500);
  }
  return _json(<String, dynamic>{'message': 'not found'}, statusCode: 404);
});

/// A server that validates the cookie but now reports a renamed person.
_FakeHttpAdapter _renamedAdapter() => _FakeHttpAdapter((options) async {
  if (options.path == '/api/auth/get-session') { // glossary:allow Better Auth auth session, not the domain Visit
    return _json(<String, dynamic>{
      'user': <String, dynamic>{
        'id': 'u1',
        'email': 'ada@example.com',
        'name': 'Ada Byron',
      },
    });
  }
  return _json(<String, dynamic>{'message': 'not found'}, statusCode: 404);
});

/// A server that answers 200 but with a malformed user, so parsing fails.
_FakeHttpAdapter _malformedAdapter() => _FakeHttpAdapter(
  (options) async => _json(<String, dynamic>{
    'user': <String, dynamic>{
      'id': 123,
      'email': 'ada@example.com',
      'name': 'Ada Lovelace',
    },
  }),
);

Site _site() => Site(
  id: 'site-1',
  projectId: 'project-1',
  geometry: const PointGeometry(LatLng(45.0, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

Widget _accountApp(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const AccountScreen(),
  ),
);

void main() {
  testWidgets(
    'relaunching with a persisted sign-in restores it and shows the name without credentials',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'ibis_auth_session', // glossary:allow Better Auth auth session, not the domain Visit
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final path = '${directory.path}/ibis.sqlite';

      late AppDatabase database;
      late ProviderContainer container;
      // The store and the auth transport are real I/O, so they run outside the
      // widget test's fake-async zone.
      await tester.runAsync(() async {
        // First launch: the person signs in and the auth session is persisted. // glossary:allow Better Auth auth session, not the domain Visit
        final first = AppDatabase.open(path);
        final firstContainer = _container(first, _validatingAdapter());
        await firstContainer
            .read(authProvider.notifier)
            .signIn(email: 'ada@example.com', password: 'correct');
        expect(firstContainer.read(authProvider).value?.name, 'Ada Lovelace');
        // Kill the first launch; its in-memory cookie is gone.
        firstContainer.dispose();
        await first.close();

        // Relaunch against the same store; no credentials are entered.
        database = AppDatabase.open(path);
        container = _container(database, _validatingAdapter());
        await container.read(authProvider.notifier).restore();
      });
      addTearDown(database.close);
      addTearDown(container.dispose);

      await tester.pumpWidget(_accountApp(container));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ada Lovelace'), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_in')), findsNothing);
    },
  );

  testWidgets(
    'a persisted sign-in the server rejects is cleared and shows the signed-out state',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      late ProviderContainer container;
      late bool cleared;
      await tester.runAsync(() async {
        await AuthSessionDao(database) // glossary:allow Better Auth auth session, not the domain Visit
            .save(person: _ada, cookie: _persistedCookie);
        container = _container(database, _rejectingAdapter());
        await container.read(authProvider.notifier).restore();
        cleared = await AuthSessionDao(database).read() == null; // glossary:allow Better Auth auth session, not the domain Visit
      });
      addTearDown(container.dispose);

      expect(container.read(authProvider).value, isNull);
      expect(cleared, isTrue);

      await tester.pumpWidget(_accountApp(container));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_sign_in')), findsOneWidget);
      expect(find.textContaining('Ada Lovelace'), findsNothing);
    },
  );

  test('a Visit queued before the relaunch is delivered once the persisted sign-in is restored', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await SiteDao(database).save(_site());
    final visitDao = VisitDao(database);
    final started = await visitDao.startVisit(
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'protocol-version-1',
    );
    final ended = await visitDao.endVisit(started);
    await OutboxDao(database).enqueue(ended.id);
    await AuthSessionDao(database).save(person: _ada, cookie: _persistedCookie); // glossary:allow Better Auth auth session, not the domain Visit

    final container = _container(database, _validatingAdapter());
    addTearDown(container.dispose);

    // No sign-in call: the persisted sign-in is restored and its cookie is
    // attached before the app-start flush runs.
    await container.read(authProvider.notifier).restore();
    expect(container.read(authProvider).value?.name, 'Ada Lovelace');

    await container.read(outboxStartupProvider.future);

    expect(await OutboxDao(database).syncStateOf(ended.id), SyncState.synced);
    expect((await visitDao.findById(ended.id))!.state, VisitState.submitted);
  });

  test(
    'a relaunch while the server is unreachable keeps the persisted sign-in',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await AuthSessionDao(database) // glossary:allow Better Auth auth session, not the domain Visit
          .save(person: _ada, cookie: _persistedCookie);

      final container = _container(database, _offlineAdapter());
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).restore();

      expect(container.read(authProvider).value?.name, 'Ada Lovelace');
      expect(await AuthSessionDao(database).read(), isNotNull); // glossary:allow Better Auth auth session, not the domain Visit
    },
  );

  test('signing out clears the persisted sign-in', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await AuthSessionDao(database).save(person: _ada, cookie: _persistedCookie); // glossary:allow Better Auth auth session, not the domain Visit
    final adapter = _FakeHttpAdapter(
      (options) async => _json(<String, dynamic>{'success': true}),
    );
    final container = _container(database, adapter);
    addTearDown(container.dispose);

    expect(await AuthSessionDao(database).read(), isNotNull); // glossary:allow Better Auth auth session, not the domain Visit

    await container.read(authProvider.notifier).signOut();

    expect(await AuthSessionDao(database).read(), isNull); // glossary:allow Better Auth auth session, not the domain Visit
  });

  test('a relaunch that hits a 5xx keeps the persisted sign-in', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await AuthSessionDao(database).save(person: _ada, cookie: _persistedCookie); // glossary:allow Better Auth auth session, not the domain Visit
    final container = _container(database, _serverFaultAdapter());
    addTearDown(container.dispose);

    await container.read(authProvider.notifier).restore();

    expect(container.read(authProvider).value?.name, 'Ada Lovelace');
    expect(await AuthSessionDao(database).read(), isNotNull); // glossary:allow Better Auth auth session, not the domain Visit
  });

  test('a hanging get-session does not block the launch indefinitely', () async { // glossary:allow Better Auth auth session, not the domain Visit
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await AuthSessionDao(database).save(person: _ada, cookie: _persistedCookie); // glossary:allow Better Auth auth session, not the domain Visit
    final container = _container(
      database,
      _hangingAdapter(),
      requestTimeout: const Duration(milliseconds: 50),
    );
    addTearDown(container.dispose);

    final stopwatch = Stopwatch()..start();
    await container.read(authProvider.notifier).restore();
    stopwatch.stop();

    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(container.read(authProvider).value?.name, 'Ada Lovelace');
    expect(await AuthSessionDao(database).read(), isNotNull); // glossary:allow Better Auth auth session, not the domain Visit
  });

  test('a successful validate refreshes the persisted person', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await AuthSessionDao(database).save(person: _ada, cookie: _persistedCookie); // glossary:allow Better Auth auth session, not the domain Visit
    final container = _container(database, _renamedAdapter());
    addTearDown(container.dispose);

    await container.read(authProvider.notifier).restore();

    final stored = await AuthSessionDao(database).read(); // glossary:allow Better Auth auth session, not the domain Visit
    expect(stored?.person.name, 'Ada Byron');
    expect(container.read(authProvider).value?.name, 'Ada Byron');
  });

  test('a malformed get-session response is not masked as a stale sign-in', () async { // glossary:allow Better Auth auth session, not the domain Visit
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await AuthSessionDao(database).save(person: _ada, cookie: _persistedCookie); // glossary:allow Better Auth auth session, not the domain Visit
    final container = _container(database, _malformedAdapter());
    addTearDown(container.dispose);

    await expectLater(
      container.read(authProvider.notifier).restore(),
      throwsA(isA<TypeError>()),
    );
  });
}
