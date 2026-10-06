import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/projects/projects_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/projects/projects_client.dart';

Project project({
  String id = 'p1',
  String name = 'Alpine Birds',
  String? description,
}) => Project(
  id: id,
  name: name,
  description: description,
  validationEnabled: false,
  sensitiveTaxaObfuscation: true,
  taxonomicReferenceId: 'it-flora',
  taxonomicReferenceVersion: '2024.1',
);

/// A Project card is self-contained: render it with the app's localizations so
/// text lookups match the real screen.
Widget cardHarness(Project value) => MaterialApp(
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: ProjectCard(project: value)),
);

/// Fakes the create request so a Project can reach the list without a server:
/// `POST /projects` echoes the submitted name and reference under a fresh id.
class FakeAdapter implements HttpClientAdapter {
  int _next = 1;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/projects' && options.method == 'POST') {
      final body = (options.data! as Map).cast<String, dynamic>();
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'id': 'p${_next++}',
          'name': body['name'],
          'settings': <String, dynamic>{
            'validationEnabled': body['validationEnabled'],
            'sensitiveTaxaObfuscation': body['sensitiveTaxaObfuscation'],
          },
          'taxonomicReferenceId': body['taxonomicReferenceId'],
          'taxonomicReferenceVersion': body['taxonomicReferenceVersion'],
        }),
        201,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'message': 'not found'}),
      404,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProjectsClient fakeClient(FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
    ..httpClientAdapter = adapter;
  return ProjectsClient(
    baseUrl: 'http://test.local',
    auth: AuthClient(baseUrl: 'http://test.local', dio: dio),
    dio: dio,
  );
}

/// Runs the screen under the routes it navigates to, with the create client
/// faked.
Widget screenHarness(ProjectsClient client) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const ProjectsScreen()),
      GoRoute(
        path: '/account',
        builder: (context, state) =>
            const Scaffold(body: Text('account-surface')),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const Scaffold(body: Text('help-surface')),
      ),
      GoRoute(
        path: '/projects/:projectId',
        builder: (context, state) => const Scaffold(body: Text('project-hub')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [projectsClientProvider.overrideWithValue(client)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// Lets the real HTTP future complete without hanging the test.
Future<void> flush(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

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

void main() {
  testWidgets('C1: a Project card shows its name and reference version', (
    tester,
  ) async {
    await tester.pumpWidget(cardHarness(project()));

    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Alpine Birds'), findsOneWidget);
    expect(find.text('2024.1'), findsOneWidget);
  });

  testWidgets('C1: the list renders one card per Project', (tester) async {
    await tester.pumpWidget(screenHarness(fakeClient(FakeAdapter())));
    await tester.pumpAndSettle();

    await createProject(tester, 'Alpine Birds');
    await createProject(tester, 'River Survey');

    expect(find.byType(ProjectCard), findsNWidgets(2));
    expect(find.text('Alpine Birds'), findsOneWidget);
    expect(find.text('River Survey'), findsOneWidget);
  });

  testWidgets('C2: a card shows the authored description when set', (
    tester,
  ) async {
    await tester.pumpWidget(
      cardHarness(project(description: 'Mountain transects')),
    );

    expect(find.text('Alpine Birds'), findsOneWidget);
    expect(find.text('2024.1'), findsOneWidget);
    expect(find.text('Mountain transects'), findsOneWidget);
  });

  testWidgets('C1: the card body text is at least 16 sp (UX-002)', (
    tester,
  ) async {
    await tester.pumpWidget(
      cardHarness(project(description: 'Mountain transects')),
    );

    final version = tester.widget<Text>(find.text('2024.1'));
    final description = tester.widget<Text>(find.text('Mountain transects'));
    expect(version.style?.fontSize, greaterThanOrEqualTo(16.0));
    expect(description.style?.fontSize, greaterThanOrEqualTo(16.0));
  });

  testWidgets('C3: a card shows only basic info when no description is set', (
    tester,
  ) async {
    await tester.pumpWidget(cardHarness(project()));

    final texts = tester
        .widgetList<Text>(
          find.descendant(of: find.byType(Card), matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .toList();
    expect(texts, <String>['Alpine Birds', '2024.1']);
  });

  testWidgets('C3: a whitespace-only description is not shown', (tester) async {
    await tester.pumpWidget(cardHarness(project(description: '   ')));

    final texts = tester
        .widgetList<Text>(
          find.descendant(of: find.byType(Card), matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .toList();
    expect(texts, <String>['Alpine Birds', '2024.1']);
  });

  testWidgets('C5: a Project with no pinned reference carries a badge '
      '(UX-034)', (tester) async {
    await tester.pumpWidget(
      cardHarness(
        const Project(
          id: 'p1',
          name: 'Alpine Birds',
          validationEnabled: false,
          sensitiveTaxaObfuscation: true,
        ),
      ),
    );

    expect(find.byKey(const Key('project_no_reference_p1')), findsOneWidget);
    expect(find.text('No reference pinned'), findsOneWidget);
  });

  testWidgets('C5: the no-reference badge offers the pin action (UX-034)', (
    tester,
  ) async {
    var pinned = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProjectCard(
            project: const Project(
              id: 'p1',
              name: 'Alpine Birds',
              validationEnabled: false,
              sensitiveTaxaObfuscation: true,
            ),
            onPinReference: () => pinned = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('project_pin_reference_p1')));
    await tester.pumpAndSettle();

    expect(pinned, isTrue);
  });

  testWidgets('C4: with no Project the list shows an empty state with a '
      'create action', (tester) async {
    await tester.pumpWidget(screenHarness(fakeClient(FakeAdapter())));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_project_empty')), findsOneWidget);
  });

  testWidgets('C4: the empty-state create action opens the project editor', (
    tester,
  ) async {
    await tester.pumpWidget(screenHarness(fakeClient(FakeAdapter())));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_project_empty')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save_project')), findsOneWidget);
  });
}
