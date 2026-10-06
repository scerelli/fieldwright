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

/// Every text style the theme exposes, for the Inter font-family check
/// (DESIGN.md § Typography).
List<TextStyle?> _allStyles(TextTheme text) => <TextStyle?>[
  text.displayLarge,
  text.displayMedium,
  text.displaySmall,
  text.headlineLarge,
  text.headlineMedium,
  text.headlineSmall,
  text.titleLarge,
  text.titleMedium,
  text.titleSmall,
  text.bodyLarge,
  text.bodyMedium,
  text.bodySmall,
  text.labelLarge,
  text.labelMedium,
  text.labelSmall,
];

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

  group('light theme carries the DESIGN.md colour tokens', () {
    final theme = buildLightTheme();

    test('colorScheme.primary is #00695C', () {
      expect(theme.colorScheme.primary, const Color(0xFF00695C));
    });

    test('colorScheme.onSurface is #14181A', () {
      expect(theme.colorScheme.onSurface, const Color(0xFF14181A));
    });

    test('colorScheme.onSurfaceVariant is #444B4E', () {
      expect(theme.colorScheme.onSurfaceVariant, const Color(0xFF444B4E));
    });

    test('scaffoldBackgroundColor is #F6F8F9', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F8F9));
    });

    test('colorScheme.surface is #FFFFFF', () {
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
    });
  });

  group('dark theme carries the DESIGN.md colour tokens', () {
    final theme = buildDarkTheme();

    test('colorScheme.surface is #263238', () {
      expect(theme.colorScheme.surface, const Color(0xFF263238));
    });

    test('scaffoldBackgroundColor is #263238', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFF263238));
    });

    test('colorScheme.onSurface is #E3E9EA', () {
      expect(theme.colorScheme.onSurface, const Color(0xFFE3E9EA));
    });

    test('colorScheme.primary is #80CBC4', () {
      expect(theme.colorScheme.primary, const Color(0xFF80CBC4));
    });

    test('colorScheme.secondary is #4DD0E1', () {
      expect(theme.colorScheme.secondary, const Color(0xFF4DD0E1));
    });

    test('colorScheme.tertiary is #C792EA', () {
      expect(theme.colorScheme.tertiary, const Color(0xFFC792EA));
    });
  });

  group('typography follows DESIGN.md', () {
    test('the light theme text styles use the Inter font family', () {
      for (final style in _allStyles(buildLightTheme().textTheme)) {
        expect(style?.fontFamily, kFontFamily);
      }
    });

    test('the dark theme text styles use the Inter font family', () {
      for (final style in _allStyles(buildDarkTheme().textTheme)) {
        expect(style?.fontFamily, kFontFamily);
      }
    });

    test('a numeric text style applies tabular figures', () {
      for (final theme in <ThemeData>[buildLightTheme(), buildDarkTheme()]) {
        expect(
          theme.textTheme.bodyMedium?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });
  });
}
