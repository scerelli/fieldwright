import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/app.dart';
import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/auth/auth_provider.dart';
import 'package:ibis/projects/projects_client.dart';
import 'package:ibis/projects/members_client.dart';
import 'package:ibis/projects/survey_periods_client.dart';
import 'package:ibis/protocol_versions/protocol_versions_client.dart';
import 'package:ibis/shell/app_shell.dart';

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

Map<String, dynamic> projectJson({
  String id = 'p1',
  String name = 'Alpine Birds',
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'settings': <String, dynamic>{
    'validationEnabled': false,
    'sensitiveTaxaObfuscation': true,
  },
  'taxonomicReferenceId': 'it-flora',
  'taxonomicReferenceVersion': '2024.1',
};

/// Routes by path: `POST /projects` echoes the created Project, the members
/// and survey-period lists answer empty, and sign-in sets the auth cookie.
FakeHttpAdapter projectsAdapter() => FakeHttpAdapter((options) async {
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
        'set-cookie': <String>[
          'better-auth.session_token=session-token-123; Path=/; HttpOnly', // glossary:allow Better Auth session cookie, not the domain Visit
        ],
      },
    );
  }
  if (options.path == '/projects' && options.method == 'POST') {
    final body = (options.data! as Map).cast<String, dynamic>();
    return jsonResponse(
      projectJson(name: body['name'] as String),
      statusCode: 201,
    );
  }
  if (options.path == '/projects/p1/members' && options.method == 'GET') {
    return jsonResponse(const <dynamic>[]);
  }
  if (options.path == '/survey-periods' && options.method == 'GET') {
    return jsonResponse(const <dynamic>[]);
  }
  return jsonResponse(<String, dynamic>{
    'message': 'not found',
  }, statusCode: 404);
});

Dio fakeDio(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return dio;
}

Future<void> pumpApp(WidgetTester tester, FakeHttpAdapter adapter) async {
  final auth = AuthClient(baseUrl: 'http://test.local', dio: fakeDio(adapter));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authClientProvider.overrideWithValue(auth),
        projectsClientProvider.overrideWithValue(
          ProjectsClient(
            baseUrl: 'http://test.local',
            auth: auth,
            dio: fakeDio(adapter),
          ),
        ),
        protocolVersionsClientProvider.overrideWithValue(
          ProtocolVersionsClient(
            baseUrl: 'http://test.local',
            auth: auth,
            dio: fakeDio(adapter),
          ),
        ),
        membersClientProvider.overrideWithValue(
          MembersClient(
            baseUrl: 'http://test.local',
            auth: auth,
            dio: fakeDio(adapter),
          ),
        ),
        surveyPeriodsClientProvider.overrideWithValue(
          SurveyPeriodsClient(
            baseUrl: 'http://test.local',
            auth: auth,
            dio: fakeDio(adapter),
          ),
        ),
      ],
      child: const IbisApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets a real (non-fake-async) HTTP future complete without hanging the test.
Future<void> flush(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// Creates a Project through the editor so it appears in the Projects list.
Future<void> createProject(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('create_project')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('project_name')), name);
  await tester.enterText(
    find.byKey(const Key('project_reference_id')),
    'it-flora',
  );
  await tester.enterText(
    find.byKey(const Key('project_reference_version')),
    '2024.1',
  );
  await tester.tap(find.byKey(const Key('save_project')));
  await flush(tester);
}

/// Opens the project detail entry point from the Projects list.
Future<void> openProject(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('project_p1')));
  await tester.pumpAndSettle();
}

/// Opens the hub's Project-config overflow menu.
Future<void> openOverflow(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('project_config_overflow')));
  await tester.pumpAndSettle();
}

String currentPath(WidgetTester tester) =>
    GoRouterState.of(tester.element(find.byType(AppShell))).uri.path;

void main() {
  testWidgets(
    'a project opens its protocol version, members and survey periods',
    (tester) async {
      await pumpApp(tester, projectsAdapter());
      await createProject(tester, 'Alpine Birds');

      expect(find.text('Alpine Birds'), findsOneWidget);

      await openProject(tester);

      expect(currentPath(tester), '/projects/p1');
      expect(find.byKey(const Key('hub_sites_tab')), findsOneWidget);
      expect(find.byKey(const Key('hub_visits_tab')), findsOneWidget);

      await openOverflow(tester);
      expect(find.byKey(const Key('open_protocol_version')), findsOneWidget);
      expect(find.byKey(const Key('open_members')), findsOneWidget);
      expect(find.byKey(const Key('open_survey_periods')), findsOneWidget);

      await tester.tap(find.byKey(const Key('open_protocol_version')));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/projects/p1/protocol');
      expect(find.byKey(const Key('protocol_id')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hub_visits_tab')), findsOneWidget);
      await openOverflow(tester);
      await tester.tap(find.byKey(const Key('open_members')));
      await flush(tester);
      expect(currentPath(tester), '/projects/p1/members');
      expect(find.byKey(const Key('members_list')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hub_visits_tab')), findsOneWidget);
      await openOverflow(tester);
      await tester.tap(find.byKey(const Key('open_survey_periods')));
      await flush(tester);
      expect(currentPath(tester), '/projects/p1/survey-periods');
      expect(find.byKey(const Key('survey_periods_list')), findsOneWidget);
    },
  );

  testWidgets('each sub-screen navigates back to the project and the list', (
    tester,
  ) async {
    await pumpApp(tester, projectsAdapter());
    await createProject(tester, 'Alpine Birds');
    await openProject(tester);

    await openOverflow(tester);
    await tester.tap(find.byKey(const Key('open_protocol_version')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hub_visits_tab')), findsOneWidget);

    await openOverflow(tester);
    await tester.tap(find.byKey(const Key('open_members')));
    await flush(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hub_visits_tab')), findsOneWidget);

    await openOverflow(tester);
    await tester.tap(find.byKey(const Key('open_survey_periods')));
    await flush(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hub_visits_tab')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Alpine Birds'), findsOneWidget);
    expect(currentPath(tester), '/projects');
  });
}
