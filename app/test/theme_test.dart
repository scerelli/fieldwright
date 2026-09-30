import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/app.dart';
import 'package:ibis/shell/app_shell.dart';
import 'package:ibis/theme/app_theme.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: IbisApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('applies the dark scheme when the platform brightness is dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpApp(tester);

    final context = tester.element(find.byType(AppShell));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets(
    'defaults to the dark scheme when the platform brightness is light',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await pumpApp(tester);

      final context = tester.element(find.byType(AppShell));
      expect(Theme.of(context).brightness, Brightness.dark);
    },
  );

  testWidgets('provides a light theme and a dark theme', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });

  test('the dark theme uses the VS Code Material Dark palette', () {
    final theme = buildDarkTheme();

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, const Color(0xFF80CBC4));
    expect(theme.colorScheme.secondary, const Color(0xFF4DD0E1));
    expect(theme.colorScheme.tertiary, const Color(0xFFC792EA));
    expect(theme.colorScheme.onSurface, const Color(0xFFEEFFFF));
    expect(theme.colorScheme.surface, const Color(0xFF263238));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF263238));
  });
}
