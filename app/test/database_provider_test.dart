import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ibis/features/sites/site.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';

void main() {
  test('a Site written through the provider is readable after reopening the database', () async {
    final directory = Directory.systemTemp.createTempSync(
      'ibis_database_provider',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/ibis.sqlite';

    final site = Site(
      id: 'site-1',
      projectId: 'project-1',
      geometry: const PointGeometry(LatLng(45.0, 9.0)),
      origin: SiteOrigin.field,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final firstDatabase = AppDatabase.open(path);
    final firstContainer = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(firstDatabase)],
    );
    await firstContainer.read(siteDaoProvider).save(site);
    await firstDatabase.close();

    final secondDatabase = AppDatabase.open(path);
    final secondContainer = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(secondDatabase)],
    );
    final loaded = await secondContainer
        .read(siteDaoProvider)
        .findById(site.id);
    await secondDatabase.close();

    expect(loaded, isNotNull);
    expect(loaded!.id, site.id);
    expect(loaded.projectId, site.projectId);
    expect(loaded.origin, SiteOrigin.field);
    expect(loaded.createdAt, site.createdAt);
    expect(loaded.geometry.toJson(), site.geometry.toJson());
  });
}
