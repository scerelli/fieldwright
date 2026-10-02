import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/features/visits/visits_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

Site _site() => Site(
  id: 'site-1',
  projectId: 'project-1',
  geometry: const PointGeometry(LatLng(45.0, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

AppDatabase _openDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

Future<Visit> _submittedVisit(AppDatabase database) async {
  await SiteDao(database).save(_site());
  final dao = VisitDao(database);
  final visit = await dao.startVisit(
    siteId: 'site-1',
    surveyPeriodId: 'survey-period-1',
    protocolVersionId: 'protocol-version-1',
  );
  final ended = await dao.endVisit(visit);
  return dao.markSubmitted(ended.id);
}

Widget _app(AppDatabase database, Widget home) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  group('VisitsScreen with a submitted Visit', () {
    testWidgets(
      'shows the submitted label and icon, not the in-progress ones',
      (tester) async {
        final database = _openDatabase();
        final submitted = await _submittedVisit(database);

        await tester.pumpWidget(
          _app(
            database,
            const VisitsScreen(
              projectId: 'project-1',
              surveyPeriodId: 'survey-period-1',
              protocolVersionId: 'protocol-version-1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(Key('visit_${submitted.id}')), findsOneWidget);
        expect(find.text('Submitted'), findsOneWidget);
        expect(find.text('In progress'), findsNothing);
        expect(
          find.byIcon(Icons.assignment_turned_in_outlined),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.timelapse_outlined), findsNothing);
      },
    );

    testWidgets('offers no End Visit action', (tester) async {
      final database = _openDatabase();
      final submitted = await _submittedVisit(database);

      await tester.pumpWidget(
        _app(
          database,
          const VisitsScreen(
            projectId: 'project-1',
            surveyPeriodId: 'survey-period-1',
            protocolVersionId: 'protocol-version-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('end_visit_${submitted.id}')), findsNothing);
    });
  });

  group('CaptureScreen with a submitted Visit', () {
    testWidgets('shows the submitted state label', (tester) async {
      final database = _openDatabase();
      final submitted = await _submittedVisit(database);

      await tester.pumpWidget(_app(database, CaptureScreen(visit: submitted)));
      await tester.pumpAndSettle();

      expect(find.text('State: Submitted'), findsOneWidget);
      expect(find.text('State: In progress'), findsNothing);
    });
  });
}
