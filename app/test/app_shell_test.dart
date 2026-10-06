import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/app.dart';
import 'package:ibis/features/account/account_screen.dart';
import 'package:ibis/features/projects/projects_screen.dart';
import 'package:ibis/features/sites/sites_screen.dart';
import 'package:ibis/features/visits/visits_screen.dart';
import 'package:ibis/router/app_router.dart';
import 'package:ibis/shell/app_shell.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: IbisApp()));
  await tester.pumpAndSettle();
}

String currentPath(WidgetTester tester) =>
    GoRouterState.of(tester.element(find.byType(AppShell))).uri.path;

void main() {
  testWidgets('the app opens on the Projects list at /projects', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(currentPath(tester), '/projects');
    expect(find.byType(ProjectsScreen), findsOneWidget);
  });

  testWidgets('the Projects list renders no bottom navigation bar', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Account opens from the app bar on the Projects list', (
    tester,
  ) async {
    await pumpApp(tester);

    final account = find.byKey(const Key('open_account'));
    expect(account, findsOneWidget);

    await tester.tap(account);
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/account');
    expect(find.byType(AccountScreen), findsOneWidget);
  });

  testWidgets('no top-level route lists Sites or Visits across Projects '
      '(UX-019)', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const IbisApp()),
    );
    await tester.pumpAndSettle();

    router.go('/sites');
    await tester.pumpAndSettle();
    expect(find.byType(SitesScreen), findsNothing);

    router.go('/visits');
    await tester.pumpAndSettle();
    expect(find.byType(VisitsScreen), findsNothing);
  });
}
