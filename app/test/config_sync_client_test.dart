import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/outbox/config_sync_client.dart';

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

// The Better Auth cookie identifies the request; it is not the domain Visit.
const String authCookie = 'better-auth.session_token=auth-token-123'; // glossary:allow Better Auth session cookie, not the domain Visit

const String configPath = '/api/v1/projects/p1/config';

Map<String, dynamic> projectJson() => <String, dynamic>{
  'id': 'p1',
  'name': 'River survey',
  'settings': <String, dynamic>{
    'validationEnabled': true,
    'sensitiveTaxaObfuscation': false,
  },
  'taxonomicReferenceId': 'italy-vascular-flora',
  'taxonomicReferenceVersion': '2024.1',
};

/// The protocol document the server validates against the shared schema; it
/// carries the Target list.
Map<String, dynamic> protocolDocumentJson() => <String, dynamic>{
  'protocolId': 'alpine-birds-2026',
  'version': 1,
  'taxonomicScope': <String, dynamic>{
    'taxa': <String>['Aves'],
  },
  'targetList': <Map<String, dynamic>>[
    <String, dynamic>{
      'taxonRef': 'Aves|Turdus|merula',
      'label': 'Common blackbird',
    },
  ],
  'detectionMethods': <Map<String, dynamic>>[
    <String, dynamic>{'id': 'visual', 'label': 'Visual detection'},
  ],
  'requiredEffortFields': <String>['start'],
};

Map<String, dynamic> protocolVersionJson() => <String, dynamic>{
  'id': 'pv1',
  'projectId': 'p1',
  'protocolId': 'alpine-birds-2026',
  'version': 1,
  'document': protocolDocumentJson(),
  'frozenAt': null,
  'createdAt': '2026-09-30T00:00:00.000Z',
};

Map<String, dynamic> surveyPeriodJson() => <String, dynamic>{
  'id': 'sp1',
  'projectId': 'p1',
  'name': 'Spring 2026',
  'startDate': '2026-03-01',
  'endDate': '2026-05-31',
  'createdAt': '2026-09-30T00:00:00.000Z',
};

Map<String, dynamic> siteJson() => <String, dynamic>{
  'id': 's1',
  'projectId': 'p1',
  'name': 'Site A',
  'geom': '{"type":"Point","coordinates":[9.19,45.46]}',
  'createdAt': '2026-09-30T00:00:00.000Z',
};

Map<String, dynamic> configBody() => <String, dynamic>{
  'versionToken': '1700000000000001',
  'project': projectJson(),
  'protocolVersion': protocolVersionJson(),
  'surveyPeriods': <Map<String, dynamic>>[surveyPeriodJson()],
  'sites': <Map<String, dynamic>>[siteJson()],
};

/// Routes by path: sign-in sets the auth cookie, and the config route answers
/// with [body] (or an error carrying [message]).
FakeHttpAdapter configAdapter({
  Map<String, dynamic>? body,
  int status = 200,
  String message = 'request failed',
}) => FakeHttpAdapter((options) async {
  if (options.path == '/api/auth/sign-in/email') {
    return jsonResponse(
      <String, dynamic>{
        'user': <String, dynamic>{
          'id': 'u1',
          'email': 'ada@example.com',
          'name': 'Ada Lovelace',
        },
      },
      headers: <String, List<String>>{
        'set-cookie': <String>['$authCookie; Path=/; HttpOnly'],
      },
    );
  }
  if (options.path.startsWith('/api/v1/projects/') &&
      options.path.endsWith('/config')) {
    if (status != 200) {
      return jsonResponse(<String, dynamic>{
        'message': message,
      }, statusCode: status);
    }
    return jsonResponse(body ?? configBody());
  }
  return jsonResponse(<String, dynamic>{
    'message': 'not found',
  }, statusCode: 404);
});

AuthClient authWith(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return AuthClient(baseUrl: 'http://test.local', dio: dio);
}

ConfigSyncClient configSyncWith(FakeHttpAdapter adapter, AuthClient auth) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return ConfigSyncClient(baseUrl: 'http://test.local', auth: auth, dio: dio);
}

Future<AuthClient> signedInAuth(FakeHttpAdapter adapter) async {
  final auth = authWith(adapter);
  await auth.signIn(email: 'ada@example.com', password: 'correct');
  return auth;
}

void main() {
  group('ConfigSyncClient', () {
    test('pull gets the changed config since the stored token', () async {
      final adapter = configAdapter();
      final auth = await signedInAuth(adapter);
      final client = configSyncWith(adapter, auth);

      final pull = await client.pull(
        projectId: 'p1',
        since: '1700000000000000',
      );

      final request = adapter.requests.firstWhere(
        (request) => request.path == configPath,
      );
      expect(request.method, 'GET');
      expect(request.headers['cookie'], contains('auth-token-123'));
      expect(request.queryParameters['since'], '1700000000000000');

      expect(pull.versionToken, '1700000000000001');
      expect(pull.project?.id, 'p1');
      expect(pull.project?.name, 'River survey');
      expect(pull.project?.validationEnabled, isTrue);
      expect(pull.project?.taxonomicReferenceId, 'italy-vascular-flora');
      expect(
        pull.protocolVersion?.document.targetList?.single.taxonRef,
        'Aves|Turdus|merula',
      );
      expect(pull.surveyPeriods.single.name, 'Spring 2026');
      expect(pull.surveyPeriods.single.startDate, '2026-03-01');
      expect(pull.sites.single.id, 's1');
      expect(pull.sites.single.name, 'Site A');
    });

    test('an initial pull omits the since parameter', () async {
      final adapter = configAdapter();
      final auth = await signedInAuth(adapter);
      final client = configSyncWith(adapter, auth);

      await client.pull(projectId: 'p1');

      final request = adapter.requests.firstWhere(
        (request) => request.path == configPath,
      );
      expect(request.queryParameters.containsKey('since'), isFalse);
    });

    test('pull ignores response fields the client does not model', () async {
      final adapter = configAdapter(
        body: <String, dynamic>{
          'versionToken': '1700000000000001',
          'serverRelease': 'v9',
          'project': <String, dynamic>{
            ...projectJson(),
            'archivedAt': '2027-01-01T00:00:00.000Z',
          },
          'protocolVersion': <String, dynamic>{
            ...protocolVersionJson(),
            'document': <String, dynamic>{
              ...protocolDocumentJson(),
              'futureExtension': <String, dynamic>{'x': 1},
            },
            'checksum': 'abc123',
          },
          'surveyPeriods': <Map<String, dynamic>>[
            <String, dynamic>{...surveyPeriodJson(), 'colour': 'green'},
          ],
          'sites': <Map<String, dynamic>>[
            <String, dynamic>{...siteJson(), 'nickname': 'the bend'},
          ],
          'unknownTopLevel': <String, dynamic>{'anything': true},
        },
      );
      final auth = await signedInAuth(adapter);
      final client = configSyncWith(adapter, auth);

      final pull = await client.pull(
        projectId: 'p1',
        since: '1700000000000000',
      );

      expect(pull.versionToken, '1700000000000001');
      expect(pull.project?.id, 'p1');
      expect(pull.protocolVersion?.document.protocolId, 'alpine-birds-2026');
      expect(pull.surveyPeriods.single.name, 'Spring 2026');
      expect(pull.sites.single.id, 's1');
    });

    test(
      'a failed pull raises a ConfigSyncException carrying the server message',
      () async {
        final adapter = configAdapter(
          status: 404,
          message: 'project not found',
        );
        final auth = await signedInAuth(adapter);
        final client = configSyncWith(adapter, auth);

        await expectLater(
          client.pull(projectId: 'p1', since: '1700000000000000'),
          throwsA(
            isA<ConfigSyncException>().having(
              (error) => error.message,
              'message',
              'project not found',
            ),
          ),
        );
      },
    );
  });
}
