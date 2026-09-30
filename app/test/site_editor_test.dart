import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/sites/site_editor.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/site_dao.dart';

Widget wrapEditor(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

Future<SiteDao> openDao(WidgetTester tester) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return SiteDao(database);
}

Future<void> enterCoordinate(
  WidgetTester tester,
  int index,
  double latitude,
  double longitude,
) async {
  await tester.enterText(find.byKey(Key('latitude_$index')), '$latitude');
  await tester.enterText(find.byKey(Key('longitude_$index')), '$longitude');
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('save_site')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('creates a site with a point geometry', (tester) async {
    final dao = await openDao(tester);
    Site? saved;

    await tester.pumpWidget(
      wrapEditor(
        SiteEditor(
          dao: dao,
          projectId: 'project-1',
          onSaved: (site) => saved = site,
        ),
      ),
    );

    await enterCoordinate(tester, 0, 45.0, 9.0);
    await save(tester);

    expect(saved, isNotNull);
    expect(saved!.geometry, isA<PointGeometry>());
    final geometry = saved!.geometry as PointGeometry;
    expect(geometry.point, const LatLng(45.0, 9.0));

    final persisted = await dao.findById(saved!.id);
    expect(persisted!.geometry, isA<PointGeometry>());
  });

  testWidgets('creates a site with a line geometry', (tester) async {
    final dao = await openDao(tester);
    Site? saved;

    await tester.pumpWidget(
      wrapEditor(
        SiteEditor(
          dao: dao,
          projectId: 'project-1',
          onSaved: (site) => saved = site,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('geometry_line')));
    await tester.pumpAndSettle();
    await enterCoordinate(tester, 0, 45.0, 9.0);
    await enterCoordinate(tester, 1, 45.1, 9.1);
    await save(tester);

    expect(saved, isNotNull);
    expect(saved!.geometry, isA<LineGeometry>());
    final geometry = saved!.geometry as LineGeometry;
    expect(geometry.points, const [LatLng(45.0, 9.0), LatLng(45.1, 9.1)]);

    final persisted = await dao.findById(saved!.id);
    expect(persisted!.geometry, isA<LineGeometry>());
  });

  testWidgets('creates a site with a closed polygon geometry', (tester) async {
    final dao = await openDao(tester);
    Site? saved;

    await tester.pumpWidget(
      wrapEditor(
        SiteEditor(
          dao: dao,
          projectId: 'project-1',
          onSaved: (site) => saved = site,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('geometry_polygon')));
    await tester.pumpAndSettle();
    await enterCoordinate(tester, 0, 45.0, 9.0);
    await enterCoordinate(tester, 1, 45.0, 9.1);
    await enterCoordinate(tester, 2, 45.1, 9.1);
    await save(tester);

    expect(saved, isNotNull);
    expect(saved!.geometry, isA<PolygonGeometry>());
    final geometry = saved!.geometry as PolygonGeometry;
    expect(geometry.ring.first, geometry.ring.last);
    expect(geometry.ring, hasLength(4));

    final persisted = await dao.findById(saved!.id);
    expect(persisted!.geometry, isA<PolygonGeometry>());
  });

  testWidgets('a saved site records the planned origin', (tester) async {
    final dao = await openDao(tester);
    Site? saved;

    await tester.pumpWidget(
      wrapEditor(
        SiteEditor(
          dao: dao,
          projectId: 'project-1',
          onSaved: (site) => saved = site,
        ),
      ),
    );

    await enterCoordinate(tester, 0, 45.0, 9.0);
    await save(tester);

    expect(saved, isNotNull);
    expect(saved!.origin, SiteOrigin.planned);
    final persisted = await dao.findById(saved!.id);
    expect(persisted!.origin, SiteOrigin.planned);
  });

  testWidgets('updating a field site keeps its origin and identity', (
    tester,
  ) async {
    final dao = await openDao(tester);
    final fieldSite = Site(
      id: 'site-1',
      projectId: 'project-1',
      geometry: const PointGeometry(LatLng(45.0, 9.0)),
      origin: SiteOrigin.field,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await dao.save(fieldSite);
    Site? saved;

    await tester.pumpWidget(
      wrapEditor(
        SiteEditor(
          dao: dao,
          projectId: 'project-1',
          initialSite: fieldSite,
          onSaved: (site) => saved = site,
        ),
      ),
    );

    await enterCoordinate(tester, 0, 45.5, 9.5);
    await save(tester);

    expect(saved, isNotNull);
    expect(saved!.id, 'site-1');
    expect(saved!.origin, SiteOrigin.field);
    expect(saved!.createdAt, DateTime.utc(2026, 1, 1));
    final persisted = await dao.findById('site-1');
    expect(persisted!.origin, SiteOrigin.field);
  });

  testWidgets('rejects a non-numeric coordinate before saving', (tester) async {
    final dao = await openDao(tester);
    Site? saved;

    await tester.pumpWidget(
      wrapEditor(
        SiteEditor(
          dao: dao,
          projectId: 'project-1',
          onSaved: (site) => saved = site,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('latitude_0')), 'north');
    await tester.enterText(find.byKey(const Key('longitude_0')), '9.0');
    await save(tester);

    expect(saved, isNull);
    expect(find.byKey(const Key('geometry_error')), findsOneWidget);
  });

  testWidgets('rejects an out-of-range coordinate before saving', (
    tester,
  ) async {
    final dao = await openDao(tester);
    Site? saved;

    await tester.pumpWidget(
      wrapEditor(
        SiteEditor(
          dao: dao,
          projectId: 'project-1',
          onSaved: (site) => saved = site,
        ),
      ),
    );

    await enterCoordinate(tester, 0, 200.0, 9.0);
    await save(tester);

    expect(saved, isNull);
    expect(find.byKey(const Key('geometry_error')), findsOneWidget);
  });

  testWidgets('rejects a line with fewer than two distinct points', (
    tester,
  ) async {
    final dao = await openDao(tester);
    Site? saved;

    await tester.pumpWidget(
      wrapEditor(
        SiteEditor(
          dao: dao,
          projectId: 'project-1',
          onSaved: (site) => saved = site,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('geometry_line')));
    await tester.pumpAndSettle();
    await enterCoordinate(tester, 0, 45.0, 9.0);
    await enterCoordinate(tester, 1, 45.0, 9.0);
    await save(tester);

    expect(saved, isNull);
    expect(find.byKey(const Key('geometry_error')), findsOneWidget);
  });
}
