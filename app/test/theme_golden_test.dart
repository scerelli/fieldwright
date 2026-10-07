import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/router/app_router.dart';
import 'package:ibis/shell/app_shell.dart';
import 'package:ibis/shell/connectivity.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/theme/app_theme.dart';
import 'package:ibis/widgets/provisional_taxon_chip.dart';
import 'package:ibis/widgets/reference_banner.dart';

/// A [ConnectivitySource] double that reports no connection, so the shell
/// golden renders the persistent system-state indicator (UX-008).
class _OfflineConnectivity implements ConnectivitySource {
  @override
  Future<bool> isOffline() async => true;

  @override
  Stream<bool> get offlineChanges => const Stream<bool>.empty();
}

Future<void> pumpShell(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      connectivitySourceProvider.overrideWithValue(_OfflineConnectivity()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: container.read(goRouterProvider),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Asserts the shell indicator is drawn in the `outline`/on-surface tokens
/// (`DESIGN.md` § Color) — the render proof for UX-008.
void expectIndicatorUsesOutlineTokens(WidgetTester tester) {
  final indicator = find.byKey(const Key('shell_indicator_offline'));
  expect(indicator, findsOneWidget);

  final context = tester.element(indicator);
  final outline = Theme.of(context).extension<IbisTokens>()!.outline;
  final onSurface = Theme.of(context).colorScheme.onSurface;

  final container = tester.widget<Container>(indicator);
  final border = (container.decoration! as BoxDecoration).border! as Border;
  expect(border.bottom.color, outline);

  final label = tester.widget<Text>(
    find.text(AppLocalizations.of(context).systemStateOffline),
  );
  expect(label.style?.color, onSurface);
}

void main() {
  testWidgets('shell golden in the light theme', (tester) async {
    await pumpShell(tester, Brightness.light);

    final context = tester.element(find.byType(AppShell));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      Theme.of(context).extension<IbisTokens>()!.outline,
      const Color(0xFF70797C),
    );
    expectIndicatorUsesOutlineTokens(tester);

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/shell_light.png'),
    );
  });

  testWidgets('shell golden in the dark theme', (tester) async {
    await pumpShell(tester, Brightness.dark);

    final context = tester.element(find.byType(AppShell));
    expect(Theme.of(context).brightness, Brightness.dark);
    expectIndicatorUsesOutlineTokens(tester);

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/shell_dark.png'),
    );
  });

  testWidgets('status components golden in the light theme', (tester) async {
    await pumpStatusComponents(tester, buildLightTheme());

    final context = tester.element(find.byType(ReferenceBanner));
    final outline = Theme.of(context).extension<IbisTokens>()!.outline;
    expect(outline, const Color(0xFF70797C));

    expect(find.text(kProvisionalTaxonLabel), findsOneWidget);
    final chipLabel = tester.widget<Text>(find.text(kProvisionalTaxonLabel));
    expect(chipLabel.style?.color, outline);

    await expectLater(
      find.byKey(const Key('status_components_golden')),
      matchesGoldenFile('goldens/status_components_light.png'),
    );
  });

  testWidgets('status components golden in the dark theme', (tester) async {
    await pumpStatusComponents(tester, buildDarkTheme());

    final context = tester.element(find.byType(ReferenceBanner));
    final outline = Theme.of(context).extension<IbisTokens>()!.outline;

    expect(find.text(kProvisionalTaxonLabel), findsOneWidget);
    final chipLabel = tester.widget<Text>(find.text(kProvisionalTaxonLabel));
    expect(chipLabel.style?.color, outline);

    await expectLater(
      find.byKey(const Key('status_components_golden')),
      matchesGoldenFile('goldens/status_components_dark.png'),
    );
  });
}

/// Renders the provisional taxon chip and the no-reference banner (with its
/// Project-card badge variant) inline in a screen body, so the golden shows
/// the `outline`-token "not resolved" state in the named theme (`DESIGN.md`
/// § Component conventions).
Future<void> pumpStatusComponents(WidgetTester tester, ThemeData theme) async {
  tester.view.physicalSize = const Size(360, 200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: Padding(
          key: Key('status_components_golden'),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ReferenceBanner(),
              SizedBox(height: 16),
              ProvisionalTaxonChip(),
              SizedBox(height: 16),
              ReferenceCardBadge(),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
