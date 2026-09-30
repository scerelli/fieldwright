import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'store/database_provider.dart';
import 'theme/app_theme.dart';

class IbisApp extends ConsumerWidget {
  const IbisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the flush-on-auth listener alive for the app's lifetime, so pending
    // submissions are delivered as soon as the app is signed in (UX-007).
    ref.watch(outboxAuthFlushProvider);
    final router = ref.watch(goRouterProvider);
    final lightTheme = ref.watch(appLightThemeProvider);
    final darkTheme = ref.watch(appDarkThemeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: router,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
