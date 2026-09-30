import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/app.dart';
import 'package:ibis/shell/app_shell.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: IbisApp()));
  await tester.pumpAndSettle();
}

Finder navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

String currentPath(WidgetTester tester) =>
    GoRouterState.of(tester.element(find.byType(AppShell))).uri.path;

int selectedIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  testWidgets('tapping a destination changes the route and marks it active', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(currentPath(tester), '/projects');
    expect(selectedIndex(tester), 0);

    await tester.tap(navLabel('Sites'));
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/sites');
    expect(selectedIndex(tester), 1);

    await tester.tap(navLabel('Visits'));
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/visits');
    expect(selectedIndex(tester), 2);
  });

  testWidgets(
    'state entered in a destination survives navigating away and back',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Increment Projects'));
      await tester.tap(find.text('Increment Projects'));
      await tester.pump();
      expect(find.text('Projects count: 2'), findsOneWidget);

      await tester.tap(navLabel('Sites'));
      await tester.pumpAndSettle();
      await tester.tap(navLabel('Projects'));
      await tester.pumpAndSettle();

      expect(find.text('Projects count: 2'), findsOneWidget);
    },
  );

  testWidgets('each destination target is at least 48 dp', (tester) async {
    await pumpApp(tester);

    final targets = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byWidgetPredicate((widget) => widget is InkResponse),
    );
    expect(targets, findsNWidgets(4));

    for (var i = 0; i < 4; i++) {
      final size = tester.getSize(targets.at(i));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    }
  });

  testWidgets('the same four destinations appear after relaunch', (
    tester,
  ) async {
    await pumpApp(tester);
    for (final label in ['Projects', 'Sites', 'Visits', 'Account']) {
      expect(navLabel(label), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpApp(tester);

    for (final label in ['Projects', 'Sites', 'Visits', 'Account']) {
      expect(navLabel(label), findsOneWidget);
    }
  });
}
