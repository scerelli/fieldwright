import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/projects/projects_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/projects/projects_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/project_dao.dart';

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

/// Records every request. A create must write locally and reach it never
/// (`ADR-0014`).
class RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

ProjectsClient recordingClient(RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
    ..httpClientAdapter = adapter;
  return ProjectsClient(
    baseUrl: 'http://test.local',
    auth: AuthClient(baseUrl: 'http://test.local', dio: dio),
    dio: dio,
  );
}

AppDatabase openDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

/// Runs the screen under the routes it navigates to, over a real in-memory
/// local store. A [client] is supplied only to witness that no request is made.
Widget screenHarness(AppDatabase database, {ProjectsClient? client}) {
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
    overrides: [
      databaseProvider.overrideWithValue(database),
      if (client != null) projectsClientProvider.overrideWithValue(client),
    ],
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

/// Lets the local write and the provider reload settle.
Future<void> flush(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> createProject(
  WidgetTester tester,
  String name, {
  String? description,
  String referenceId = 'it-flora',
  String referenceVersion = '2024.1',
}) async {
  await tester.tap(find.byKey(const Key('create_project')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('project_name')), name);
  if (description != null) {
    await tester.enterText(
      find.byKey(const Key('project_description')),
      description,
    );
  }
  if (referenceId.isNotEmpty) {
    await tester.enterText(
      find.byKey(const Key('project_reference_id')),
      referenceId,
    );
  }
  if (referenceVersion.isNotEmpty) {
    await tester.enterText(
      find.byKey(const Key('project_reference_version')),
      referenceVersion,
    );
  }
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

  testWidgets('C1: creating a Project with no signed-in person stores it '
      'locally, lists it, and makes no network request (UX-015, INV-016, '
      'ADR-0014)', (tester) async {
    final database = openDatabase();
    final adapter = RecordingAdapter();
    await tester.pumpWidget(
      screenHarness(database, client: recordingClient(adapter)),
    );
    await tester.pumpAndSettle();

    await createProject(tester, 'Alpine Birds');

    expect(find.text('Alpine Birds'), findsOneWidget);
    expect(find.byType(ProjectCard), findsOneWidget);
    expect(adapter.requests, isEmpty);

    final stored = await ProjectDao(database).all();
    expect(stored.single.name, 'Alpine Birds');
  });

  testWidgets('C2: the list shows a stored Project on load (reopen, INV-015)', (
    tester,
  ) async {
    final database = openDatabase();
    await ProjectDao(database).save(project());

    await tester.pumpWidget(screenHarness(database));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectCard), findsOneWidget);
    expect(find.text('Alpine Birds'), findsOneWidget);
    expect(find.text('2024.1'), findsOneWidget);
  });

  testWidgets('C1: the list renders one card per stored Project', (
    tester,
  ) async {
    final database = openDatabase();
    await tester.pumpWidget(screenHarness(database));
    await tester.pumpAndSettle();

    await createProject(tester, 'Alpine Birds');
    await createProject(tester, 'River Survey');

    expect(find.byType(ProjectCard), findsNWidgets(2));
    expect(find.text('Alpine Birds'), findsOneWidget);
    expect(find.text('River Survey'), findsOneWidget);
  });

  testWidgets('C3: setting a description stores it and the card shows it '
      '(UX-022)', (tester) async {
    final database = openDatabase();
    await tester.pumpWidget(screenHarness(database));
    await tester.pumpAndSettle();

    await createProject(
      tester,
      'Alpine Birds',
      description: 'Mountain transects',
    );

    expect(find.text('Mountain transects'), findsOneWidget);

    final stored = await ProjectDao(database).all();
    expect(stored.single.description, 'Mountain transects');
  });

  testWidgets('C4: create succeeds with only a name and no pinned reference '
      '(UX-026)', (tester) async {
    final database = openDatabase();
    await tester.pumpWidget(screenHarness(database));
    await tester.pumpAndSettle();

    await createProject(
      tester,
      'Bare survey',
      referenceId: '',
      referenceVersion: '',
    );

    expect(find.text('Bare survey'), findsOneWidget);

    final stored = await ProjectDao(database).all();
    expect(stored.single.taxonomicReferenceId, isNull);
    expect(stored.single.taxonomicReferenceVersion, isNull);
  });

  testWidgets('C4: with no Project the list shows an empty state with a '
      'create action', (tester) async {
    await tester.pumpWidget(screenHarness(openDatabase()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_project_empty')), findsOneWidget);
  });

  testWidgets('C4: the empty-state create action opens the project editor', (
    tester,
  ) async {
    await tester.pumpWidget(screenHarness(openDatabase()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_project_empty')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save_project')), findsOneWidget);
  });
}
