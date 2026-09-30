import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/effort_timer.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/visit_dao.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('elapsedEffort', () {
    test('derives the elapsed effort from the persisted start and now', () {
      final startedAt = DateTime.utc(2026, 5, 1, 8, 0);

      expect(
        elapsedEffort(startedAt, DateTime.utc(2026, 5, 1, 8, 45)),
        const Duration(minutes: 45),
      );
    });

    test('depends only on the persisted start and now, not on a counter', () {
      final startedAt = DateTime.utc(2026, 4, 30, 22, 0);

      expect(
        elapsedEffort(startedAt, DateTime.utc(2026, 5, 1, 7, 30)),
        const Duration(hours: 9, minutes: 30),
      );
    });
  });

  group('EffortTimer', () {
    testWidgets(
      'after a simulated restart shows the persisted elapsed effort',
      (tester) async {
        final startedAt = DateTime.utc(2026, 5, 1, 8, 0);
        var now = DateTime.utc(2026, 5, 1, 8, 30);

        await tester.pumpWidget(
          _host(EffortTimer(startedAt: startedAt, clock: () => now)),
        );

        expect(find.text('00:30:00'), findsOneWidget);
      },
    );

    testWidgets('keeps running after the restart as the clock advances', (
      tester,
    ) async {
      final startedAt = DateTime.utc(2026, 5, 1, 8, 0);
      var now = DateTime.utc(2026, 5, 1, 8, 30);

      await tester.pumpWidget(
        _host(EffortTimer(startedAt: startedAt, clock: () => now)),
      );
      expect(find.text('00:30:00'), findsOneWidget);

      now = DateTime.utc(2026, 5, 1, 8, 31);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('00:31:00'), findsOneWidget);
    });

    testWidgets('freezes at the persisted end once the Visit has ended', (
      tester,
    ) async {
      final startedAt = DateTime.utc(2026, 5, 1, 8, 0);
      final endedAt = DateTime.utc(2026, 5, 1, 9, 0);
      var now = DateTime.utc(2026, 5, 1, 12, 0);

      await tester.pumpWidget(
        _host(
          EffortTimer(startedAt: startedAt, endedAt: endedAt, clock: () => now),
        ),
      );

      expect(find.text('01:00:00'), findsOneWidget);
    });
  });

  testWidgets(
    'the capture screen shows the persisted elapsed effort after a restart',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final startedAt = DateTime.utc(2026, 5, 1, 8, 0);
      final visit = await VisitDao(database).startVisit(
        siteId: 'site-1',
        surveyPeriodId: 'survey-period-1',
        protocolVersionId: 'protocol-version-1',
        now: startedAt,
      );
      var now = DateTime.utc(2026, 5, 1, 8, 30);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CaptureScreen(visit: visit, clock: () => now),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('00:30:00'), findsOneWidget);
    },
  );
}
