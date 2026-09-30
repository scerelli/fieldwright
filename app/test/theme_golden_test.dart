import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/router/app_router.dart';
import 'package:ibis/shell/app_shell.dart';
import 'package:ibis/theme/app_theme.dart';

Future<void> pumpShell(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      routerConfig: container.read(goRouterProvider),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shell golden in the light theme', (tester) async {
    await pumpShell(tester, Brightness.light);

    final context = tester.element(find.byType(AppShell));
    expect(Theme.of(context).brightness, Brightness.light);

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/shell_light.png'),
    );
  });

  testWidgets('shell golden in the dark theme', (tester) async {
    await pumpShell(tester, Brightness.dark);

    final context = tester.element(find.byType(AppShell));
    expect(Theme.of(context).brightness, Brightness.dark);

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/shell_dark.png'),
    );
  });
}
