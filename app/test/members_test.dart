import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/projects/members_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/projects/members_client.dart';

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

Map<String, dynamic> memberJson({
  String id = 'm1',
  String personId = 'u1',
  String role = 'collector',
  String email = 'member@example.com',
}) => <String, dynamic>{
  'id': id,
  'personId': personId,
  'projectId': 'p1',
  'role': role,
  'email': email,
};

/// Routes by path: sign-in sets the auth cookie, `GET /projects/p1/members`
/// answers with the given Memberships, and `POST /projects/p1/members` echoes
/// the stored Membership (the server returns no email; the client supplies it).
FakeHttpAdapter membersAdapter({
  List<Map<String, dynamic>> members = const <Map<String, dynamic>>[],
  int listStatus = 200,
  int addStatus = 201,
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
  if (options.path == '/projects/p1/members' && options.method == 'GET') {
    if (listStatus != 200) {
      return jsonResponse(<String, dynamic>{
        'message': 'forbidden',
      }, statusCode: listStatus);
    }
    return jsonResponse(members);
  }
  if (options.path == '/projects/p1/members' && options.method == 'POST') {
    if (addStatus != 201) {
      return jsonResponse(<String, dynamic>{
        'message': 'only the project creator can add members',
      }, statusCode: addStatus);
    }
    final body = (options.data! as Map).cast<String, dynamic>();
    return jsonResponse(<String, dynamic>{
      'id': 'm-new',
      'personId': 'u-new',
      'projectId': 'p1',
      'role': body['role'],
    }, statusCode: 201);
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

MembersClient membersWith(FakeHttpAdapter adapter, AuthClient auth) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return MembersClient(baseUrl: 'http://test.local', auth: auth, dio: dio);
}

Future<AuthClient> signedInAuth(FakeHttpAdapter adapter) async {
  final auth = authWith(adapter);
  await auth.signIn(email: 'ada@example.com', password: 'correct');
  return auth;
}

RequestOptions membersRequest(FakeHttpAdapter adapter, String method) =>
    adapter.requests.firstWhere(
      (request) =>
          request.path == '/projects/p1/members' && request.method == method,
    );

Future<void> pumpMembers(
  WidgetTester tester, {
  required MembersClient client,
  required bool isCreator,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MembersScreen(
        client: client,
        projectId: 'p1',
        isCreator: isCreator,
      ),
    ),
  );
  await flush(tester);
}

/// Lets a real (non-fake-async) HTTP future complete without hanging the test.
Future<void> flush(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> selectRole(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('member_add_role')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('MembersClient', () {
    test('list gets the project members with the auth cookie', () async {
      final adapter = membersAdapter(
        members: <Map<String, dynamic>>[
          memberJson(
            id: 'm1',
            personId: 'u1',
            role: 'creator',
            email: 'creator@example.com',
          ),
        ],
      );
      final auth = await signedInAuth(adapter);
      final client = membersWith(adapter, auth);

      final members = await client.list('p1');

      final request = membersRequest(adapter, 'GET');
      expect(request.headers['cookie'], contains('auth-token-123'));
      expect(members.single.email, 'creator@example.com');
      expect(members.single.role, MembershipRole.creator);
    });

    test('add posts the email and role with the auth cookie', () async {
      final adapter = membersAdapter();
      final auth = await signedInAuth(adapter);
      final client = membersWith(adapter, auth);

      final member = await client.add(
        projectId: 'p1',
        email: 'new@example.com',
        role: MembershipRole.validator,
      );

      final request = membersRequest(adapter, 'POST');
      expect(request.data, <String, dynamic>{
        'email': 'new@example.com',
        'role': 'validator',
      });
      expect(request.headers['cookie'], contains('auth-token-123'));
      expect(member.role, MembershipRole.validator);
      expect(member.email, 'new@example.com');
    });

    test('a rejected request raises a MembersException', () async {
      final adapter = FakeHttpAdapter((options) async {
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
        return jsonResponse(<String, dynamic>{
          'message': 'only the project creator can add members',
        }, statusCode: 403);
      });
      final auth = await signedInAuth(adapter);
      final client = membersWith(adapter, auth);

      await expectLater(
        client.add(
          projectId: 'p1',
          email: 'new@example.com',
          role: MembershipRole.collector,
        ),
        throwsA(isA<MembersException>()),
      );
    });
  });

  group('members surface', () {
    testWidgets('a creator can add a member and it appears in the list', (
      tester,
    ) async {
      final adapter = membersAdapter(
        members: <Map<String, dynamic>>[
          memberJson(
            id: 'm1',
            personId: 'u1',
            role: 'creator',
            email: 'creator@example.com',
          ),
        ],
      );
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = membersWith(adapter, auth);
      await pumpMembers(tester, client: client, isCreator: true);

      expect(find.text('creator@example.com'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('member_add_email')),
        'new@example.com',
      );
      await selectRole(tester, 'Collector');
      await tester.tap(find.byKey(const Key('member_add_submit')));
      await flush(tester);

      final request = membersRequest(adapter, 'POST');
      expect(request.data, <String, dynamic>{
        'email': 'new@example.com',
        'role': 'collector',
      });
      expect(find.text('new@example.com'), findsOneWidget);
    });

    testWidgets('a non-creator sees the member list without the add action', (
      tester,
    ) async {
      final adapter = membersAdapter(
        members: <Map<String, dynamic>>[
          memberJson(
            id: 'm1',
            personId: 'u1',
            role: 'creator',
            email: 'creator@example.com',
          ),
          memberJson(
            id: 'm2',
            personId: 'u2',
            role: 'collector',
            email: 'collector@example.com',
          ),
        ],
      );
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = membersWith(adapter, auth);
      await pumpMembers(tester, client: client, isCreator: false);

      expect(find.text('creator@example.com'), findsOneWidget);
      expect(find.text('collector@example.com'), findsOneWidget);
      expect(find.byKey(const Key('member_add_email')), findsNothing);
      expect(find.byKey(const Key('member_add_submit')), findsNothing);
      expect(
        adapter.requests.where(
          (request) =>
              request.path == '/projects/p1/members' &&
              request.method == 'POST',
        ),
        isEmpty,
      );
    });

    testWidgets('the add form rejects an invalid email before sending', (
      tester,
    ) async {
      final adapter = membersAdapter();
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = membersWith(adapter, auth);
      await pumpMembers(tester, client: client, isCreator: true);

      await tester.enterText(
        find.byKey(const Key('member_add_email')),
        'not-an-email',
      );
      await selectRole(tester, 'Collector');
      await tester.tap(find.byKey(const Key('member_add_submit')));
      await tester.pump();

      expect(find.byKey(const Key('member_add_error')), findsOneWidget);
      expect(
        adapter.requests.where(
          (request) =>
              request.path == '/projects/p1/members' &&
              request.method == 'POST',
        ),
        isEmpty,
      );
    });

    testWidgets('an unloadable member list shows an error', (tester) async {
      final adapter = membersAdapter(listStatus: 403);
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = membersWith(adapter, auth);
      await pumpMembers(tester, client: client, isCreator: false);

      expect(find.byKey(const Key('members_error')), findsOneWidget);
    });

    testWidgets('a failed add shows an error and leaves the list unchanged', (
      tester,
    ) async {
      final adapter = membersAdapter(
        addStatus: 403,
        members: <Map<String, dynamic>>[
          memberJson(
            id: 'm1',
            personId: 'u1',
            role: 'creator',
            email: 'creator@example.com',
          ),
        ],
      );
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = membersWith(adapter, auth);
      await pumpMembers(tester, client: client, isCreator: true);

      await tester.enterText(
        find.byKey(const Key('member_add_email')),
        'new@example.com',
      );
      await selectRole(tester, 'Collector');
      await tester.tap(find.byKey(const Key('member_add_submit')));
      await flush(tester);

      expect(find.byKey(const Key('member_add_error')), findsOneWidget);
      expect(find.byKey(const Key('member_m-new')), findsNothing);
      expect(find.byKey(const Key('member_m1')), findsOneWidget);
    });

    testWidgets('the add form requires a role before sending', (tester) async {
      final adapter = membersAdapter();
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = membersWith(adapter, auth);
      await pumpMembers(tester, client: client, isCreator: true);

      await tester.enterText(
        find.byKey(const Key('member_add_email')),
        'new@example.com',
      );
      await tester.tap(find.byKey(const Key('member_add_submit')));
      await tester.pump();

      expect(find.byKey(const Key('member_add_error')), findsOneWidget);
      expect(
        adapter.requests.where(
          (request) =>
              request.path == '/projects/p1/members' &&
              request.method == 'POST',
        ),
        isEmpty,
      );
    });
  });
}
