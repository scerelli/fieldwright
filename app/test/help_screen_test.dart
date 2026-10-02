import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/help/help_screen.dart';
import 'package:ibis/features/projects/projects_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'the in-app manual is reachable from the Projects list (UX-023)',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/projects',
        routes: <RouteBase>[
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open_help')), findsOneWidget);

      await tester.tap(find.byKey(const Key('open_help')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_screen')), findsOneWidget);
      expect(find.byKey(const Key('open_help')), findsNothing);
    },
  );
}
