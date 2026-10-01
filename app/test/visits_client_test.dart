import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/visits/visit_status.dart';
import 'package:ibis/features/visits/visits_client.dart';

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

const String visitPath = '/api/v1/visits/v1';
const String correctionsPath = '/api/v1/visits/v1/corrections';

/// A `submitted` Visit that has no Validation recorded (INV-013).
Map<String, dynamic> submittedStatusJson() => <String, dynamic>{
  'state': 'submitted',
  'validatorId': null,
  'validatedAt': null,
};

Map<String, dynamic> validatedStatusJson() => <String, dynamic>{
  'state': 'validated',
  'validatorId': 'u1',
  'validatedAt': '2026-09-30T12:00:00.000Z',
};

/// Two Corrections as the server returns them, oldest first (INV-001).
List<Map<String, dynamic>> correctionsJson() => <Map<String, dynamic>>[
  <String, dynamic>{
    'id': 'c1',
    'visitId': 'v1',
    'authorId': 'u1',
    'reason': 'wrong count',
    'payload': <String, dynamic>{'count': 3},
    'createdAt': '2026-09-30T10:00:00.000Z',
  },
  <String, dynamic>{
    'id': 'c2',
    'visitId': 'v1',
    'authorId': 'u2',
    'reason': 'wrong taxon',
    'payload': <String, dynamic>{'taxon': 'Aves|Turdus|merula'},
    'createdAt': '2026-09-30T11:00:00.000Z',
  },
];

/// Routes by path: sign-in sets the auth cookie; the status and corrections
/// routes answer with their body (or an error carrying [message]).
FakeHttpAdapter visitsAdapter({
  Map<String, dynamic>? statusBody,
  List<Map<String, dynamic>>? correctionsBody,
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
  if (options.path == correctionsPath) {
    if (status != 200) {
      return jsonResponse(<String, dynamic>{
        'message': message,
      }, statusCode: status);
    }
    return jsonResponse(correctionsBody ?? correctionsJson());
  }
  if (options.path == visitPath) {
    if (status != 200) {
      return jsonResponse(<String, dynamic>{
        'message': message,
      }, statusCode: status);
    }
    return jsonResponse(statusBody ?? submittedStatusJson());
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

VisitsClient visitsWith(FakeHttpAdapter adapter, AuthClient auth) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return VisitsClient(baseUrl: 'http://test.local', auth: auth, dio: dio);
}

Future<AuthClient> signedInAuth(FakeHttpAdapter adapter) async {
  final auth = authWith(adapter);
  await auth.signIn(email: 'ada@example.com', password: 'correct');
  return auth;
}

void main() {
  group('VisitsClient', () {
    test('readStatus parses a submitted Visit with no Validation', () async {
      final adapter = visitsAdapter();
      final auth = await signedInAuth(adapter);
      final client = visitsWith(adapter, auth);

      final status = await client.readStatus('v1');

      final request = adapter.requests.singleWhere(
        (request) => request.path == visitPath,
      );
      expect(request.method, 'GET');

      expect(status.state, VisitLifecycleState.submitted);
      expect(status.validatorId, isNull);
      expect(status.validatedAt, isNull);
    });

    test('readStatus parses a validated Visit validator and time', () async {
      final adapter = visitsAdapter(statusBody: validatedStatusJson());
      final auth = await signedInAuth(adapter);
      final client = visitsWith(adapter, auth);

      final status = await client.readStatus('v1');

      expect(status.state, VisitLifecycleState.validated);
      expect(status.validatorId, 'u1');
      expect(status.validatedAt, DateTime.utc(2026, 9, 30, 12));
    });

    test('listCorrections returns Corrections oldest first', () async {
      final adapter = visitsAdapter();
      final auth = await signedInAuth(adapter);
      final client = visitsWith(adapter, auth);

      final corrections = await client.listCorrections('v1');

      final request = adapter.requests.singleWhere(
        (request) => request.path == correctionsPath,
      );
      expect(request.method, 'GET');

      expect(
        corrections.map((correction) => correction.reason).toList(),
        <String>['wrong count', 'wrong taxon'],
      );
    });

    test(
      'a Correction parses its author, createdAt, reason and payload',
      () async {
        final adapter = visitsAdapter();
        final auth = await signedInAuth(adapter);
        final client = visitsWith(adapter, auth);

        final correction = (await client.listCorrections('v1')).first;

        expect(correction.authorId, 'u1');
        expect(correction.createdAt, DateTime.utc(2026, 9, 30, 10));
        expect(correction.reason, 'wrong count');
        expect(correction.payload, <String, dynamic>{'count': 3});
      },
    );

    test('a 404 raises VisitsException carrying the server message', () async {
      final adapter = visitsAdapter(
        status: 404,
        message: 'Visit v1 does not exist',
      );
      final auth = await signedInAuth(adapter);
      final client = visitsWith(adapter, auth);

      await expectLater(
        client.readStatus('v1'),
        throwsA(
          isA<VisitsException>().having(
            (error) => error.message,
            'message',
            'Visit v1 does not exist',
          ),
        ),
      );
    });

    test('both requests carry the sign-in headers', () async {
      final adapter = visitsAdapter();
      final auth = await signedInAuth(adapter);
      final client = visitsWith(adapter, auth);

      await client.readStatus('v1');
      await client.listCorrections('v1');

      final visitRequest = adapter.requests.singleWhere(
        (request) => request.path == visitPath,
      );
      final correctionsRequest = adapter.requests.singleWhere(
        (request) => request.path == correctionsPath,
      );
      expect(visitRequest.headers['cookie'], contains('auth-token-123'));
      expect(correctionsRequest.headers['cookie'], contains('auth-token-123'));
    });
  });
}
