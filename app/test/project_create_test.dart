import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/auth/auth_provider.dart';
import 'package:ibis/features/projects/projects_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/projects/projects_client.dart';

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

const String sessionCookie = 'better-auth.session_token=session-token-123';

Map<String, dynamic> projectJson({
  String id = 'p1',
  String name = 'Alpine Birds',
  bool validationEnabled = false,
  bool sensitiveTaxaObfuscation = true,
  String? taxonomicReferenceId = 'it-flora',
  String? taxonomicReferenceVersion = '2024.1',
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'settings': <String, dynamic>{
    'validationEnabled': validationEnabled,
    'sensitiveTaxaObfuscation': sensitiveTaxaObfuscation,
  },
  'taxonomicReferenceId': taxonomicReferenceId,
  'taxonomicReferenceVersion': taxonomicReferenceVersion,
};

/// Routes by path: sign-in sets the session cookie, `POST /projects` echoes the
/// settings back as the created Project.
FakeHttpAdapter signedInAdapter() => FakeHttpAdapter((options) async {
  switch (options.path) {
    case '/api/auth/sign-in/email':
      return jsonResponse(
        <String, dynamic>{
          'user': <String, dynamic>{
            'id': 'u1',
            'email': 'ada@example.com',
            'name': 'Ada Lovelace',
          },
        },
        headers: <String, List<String>>{
          'set-cookie': <String>['$sessionCookie; Path=/; HttpOnly'],
        },
      );
    case '/projects':
      final body = (options.data! as Map).cast<String, dynamic>();
      return jsonResponse(
        projectJson(
          name: body['name'] as String,
          validationEnabled: body['validationEnabled'] as bool,
          sensitiveTaxaObfuscation: body['sensitiveTaxaObfuscation'] as bool,
          taxonomicReferenceId: body['taxonomicReferenceId'] as String?,
          taxonomicReferenceVersion:
              body['taxonomicReferenceVersion'] as String?,
        ),
        statusCode: 201,
      );
    default:
      return jsonResponse(<String, dynamic>{
        'message': 'not found',
      }, statusCode: 404);
  }
});

AuthClient authWith(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return AuthClient(baseUrl: 'http://test.local', dio: dio);
}

ProjectsClient projectsWith(FakeHttpAdapter adapter, AuthClient auth) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return ProjectsClient(baseUrl: 'http://test.local', auth: auth, dio: dio);
}

Future<AuthClient> signedInAuth(FakeHttpAdapter adapter) async {
  final auth = authWith(adapter);
  await auth.signIn(email: 'ada@example.com', password: 'correct');
  return auth;
}

RequestOptions projectRequest(FakeHttpAdapter adapter) =>
    adapter.requests.firstWhere((request) => request.path == '/projects');

Future<void> pumpProjects(
  WidgetTester tester, {
  required AuthClient auth,
  required ProjectsClient client,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authClientProvider.overrideWithValue(auth),
        projectsClientProvider.overrideWithValue(client),
      ],
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProjectsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> openEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('create_project')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> fillEditor(
  WidgetTester tester, {
  required String name,
  required String referenceId,
  required String referenceVersion,
}) async {
  await tester.enterText(find.byKey(const Key('project_name')), name);
  await tester.enterText(
    find.byKey(const Key('project_reference_id')),
    referenceId,
  );
  await tester.enterText(
    find.byKey(const Key('project_reference_version')),
    referenceVersion,
  );
}

Future<void> saveEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('save_project')));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('ProjectsClient', () {
    test('a create request carries the session captured at sign-in', () async {
      final adapter = signedInAdapter();
      final auth = await signedInAuth(adapter);
      final client = projectsWith(adapter, auth);

      final project = await client.create(
        const CreateProjectInput(
          name: 'Alpine Birds',
          validationEnabled: false,
          sensitiveTaxaObfuscation: true,
          taxonomicReferenceId: 'it-flora',
          taxonomicReferenceVersion: '2024.1',
        ),
      );

      final request = projectRequest(adapter);
      expect(request.headers['cookie'], contains('session-token-123'));
      expect(project.name, 'Alpine Birds');
      expect(project.taxonomicReferenceVersion, '2024.1');
    });

    test('create posts every setting to /projects', () async {
      final adapter = signedInAdapter();
      final auth = await signedInAuth(adapter);
      final client = projectsWith(adapter, auth);

      await client.create(
        const CreateProjectInput(
          name: 'Wetland Survey',
          validationEnabled: true,
          sensitiveTaxaObfuscation: false,
          taxonomicReferenceId: 'it-flora',
          taxonomicReferenceVersion: '2025.2',
        ),
      );

      final request = projectRequest(adapter);
      expect(request.method, 'POST');
      expect(request.data, <String, dynamic>{
        'name': 'Wetland Survey',
        'validationEnabled': true,
        'sensitiveTaxaObfuscation': false,
        'taxonomicReferenceId': 'it-flora',
        'taxonomicReferenceVersion': '2025.2',
      });
    });

    test(
      'create posts a Project with only its name and no pinned reference',
      () async {
        final adapter = signedInAdapter();
        final auth = await signedInAuth(adapter);
        final client = projectsWith(adapter, auth);

        final project = await client.create(
          const CreateProjectInput(name: 'Bare survey'),
        );

        expect(project.name, 'Bare survey');
        expect(project.taxonomicReferenceId, isNull);
        expect(project.taxonomicReferenceVersion, isNull);
        expect(projectRequest(adapter).data, <String, dynamic>{
          'name': 'Bare survey',
          'validationEnabled': false,
          'sensitiveTaxaObfuscation': true,
          'taxonomicReferenceId': null,
          'taxonomicReferenceVersion': null,
        });
      },
    );

    test('a Project with no pinned reference carries none', () {
      final project = Project.fromJson(<String, dynamic>{
        'id': 'p1',
        'name': 'Bare survey',
        'settings': <String, dynamic>{
          'validationEnabled': false,
          'sensitiveTaxaObfuscation': true,
        },
      });

      expect(project.taxonomicReferenceId, isNull);
      expect(project.taxonomicReferenceVersion, isNull);
    });
  });

  group('create-project surface', () {
    testWidgets('creating a project adds it to the projects list', (
      tester,
    ) async {
      final adapter = signedInAdapter();
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = projectsWith(adapter, auth);
      await pumpProjects(tester, auth: auth, client: client);

      await openEditor(tester);
      await fillEditor(
        tester,
        name: 'Alpine Birds',
        referenceId: 'it-flora',
        referenceVersion: '2024.1',
      );
      await saveEditor(tester);

      final request = projectRequest(adapter);
      expect(request.method, 'POST');
      expect(request.data['name'], 'Alpine Birds');
      expect(request.headers['cookie'], contains('session-token-123'));
    });

    testWidgets(
      'the form sends validation, obfuscation and the pinned reference version',
      (tester) async {
        final adapter = signedInAdapter();
        late final AuthClient auth;
        await tester.runAsync(() async {
          auth = await signedInAuth(adapter);
        });
        final client = projectsWith(adapter, auth);
        await pumpProjects(tester, auth: auth, client: client);

        await openEditor(tester);
        await fillEditor(
          tester,
          name: 'Wetland Survey',
          referenceId: 'it-flora',
          referenceVersion: '2025.2',
        );
        await tester.tap(find.byKey(const Key('project_validation')));
        await tester.tap(find.byKey(const Key('project_obfuscation')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await saveEditor(tester);

        expect(projectRequest(adapter).data, <String, dynamic>{
          'name': 'Wetland Survey',
          'validationEnabled': true,
          'sensitiveTaxaObfuscation': false,
          'taxonomicReferenceId': 'it-flora',
          'taxonomicReferenceVersion': '2025.2',
        });
      },
    );

    testWidgets(
      'UX-025: an empty name reports under the name field and stores nothing',
      (tester) async {
        final adapter = signedInAdapter();
        late final AuthClient auth;
        await tester.runAsync(() async {
          auth = await signedInAuth(adapter);
        });
        final client = projectsWith(adapter, auth);
        await pumpProjects(tester, auth: auth, client: client);

        await openEditor(tester);
        await saveEditor(tester);

        final name = tester.widget<TextField>(
          find.byKey(const Key('project_name')),
        );
        expect(name.decoration?.errorText, 'Enter a project name.');
        expect(
          adapter.requests.where((request) => request.path == '/projects'),
          isEmpty,
        );
      },
    );

    testWidgets(
      'UX-025: a reference id with no version reports under the version field',
      (tester) async {
        final adapter = signedInAdapter();
        late final AuthClient auth;
        await tester.runAsync(() async {
          auth = await signedInAuth(adapter);
        });
        final client = projectsWith(adapter, auth);
        await pumpProjects(tester, auth: auth, client: client);

        await openEditor(tester);
        await fillEditor(
          tester,
          name: 'Alpine Birds',
          referenceId: 'it-flora',
          referenceVersion: '',
        );
        await saveEditor(tester);

        final version = tester.widget<TextField>(
          find.byKey(const Key('project_reference_version')),
        );
        expect(
          version.decoration?.errorText,
          'Enter a taxonomic reference version.',
        );
        expect(
          adapter.requests.where((request) => request.path == '/projects'),
          isEmpty,
        );
      },
    );

    testWidgets(
      'UX-025: a reference version with no id reports under the id field',
      (tester) async {
        final adapter = signedInAdapter();
        late final AuthClient auth;
        await tester.runAsync(() async {
          auth = await signedInAuth(adapter);
        });
        final client = projectsWith(adapter, auth);
        await pumpProjects(tester, auth: auth, client: client);

        await openEditor(tester);
        await tester.enterText(
          find.byKey(const Key('project_name')),
          'Alpine Birds',
        );
        await tester.enterText(
          find.byKey(const Key('project_reference_version')),
          '2024.1',
        );
        await saveEditor(tester);

        final id = tester.widget<TextField>(
          find.byKey(const Key('project_reference_id')),
        );
        expect(id.decoration?.errorText, 'Select a taxonomic reference.');
        expect(
          adapter.requests.where((request) => request.path == '/projects'),
          isEmpty,
        );
      },
    );

    testWidgets(
      'C1: the create form saves with only its name and no pinned reference',
      (tester) async {
        final adapter = signedInAdapter();
        late final AuthClient auth;
        await tester.runAsync(() async {
          auth = await signedInAuth(adapter);
        });
        final client = projectsWith(adapter, auth);
        await pumpProjects(tester, auth: auth, client: client);

        await openEditor(tester);
        await tester.enterText(
          find.byKey(const Key('project_name')),
          'Bare survey',
        );
        await saveEditor(tester);

        final request = projectRequest(adapter);
        expect(request.method, 'POST');
        expect(request.data['name'], 'Bare survey');
        expect(request.data['taxonomicReferenceId'], isNull);
        expect(request.data['taxonomicReferenceVersion'], isNull);
      },
    );

    testWidgets('C4: the create form name field carries no helper text', (
      tester,
    ) async {
      final adapter = signedInAdapter();
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = projectsWith(adapter, auth);
      await pumpProjects(tester, auth: auth, client: client);

      await openEditor(tester);

      final name = tester.widget<TextField>(
        find.byKey(const Key('project_name')),
      );
      expect(name.decoration?.helperText, isNull);
    });
  });
}
