import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/sites/map_tile_cache.dart';
import 'package:ibis/features/sites/sites_map.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';

const _tileUrl = 'https://tile.openstreetmap.org/0/0/0.png';

// A 1x1 transparent PNG, the bytes a successful online fetch would return.
final Uint8List _tileBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGBgAAAABQABpfZFQAAAAABJRU5ErkJggg==',
);

typedef _TileHeader = CachedMapTileMetadata; // glossary:allow flutter_map API

_TileHeader _tileHeader() => _TileHeader(
  staleAt: DateTime.utc(2030),
  lastModified: DateTime.utc(2026, 1, 1),
  etag: 'test-etag',
);

Directory _temporaryDirectory() {
  final directory = Directory.systemTemp.createTempSync('ibis-map-tiles');
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}

void main() {
  test(
    'serves a stored tile as fresh, so it is used with no connection',
    () async {
      final cache = MapTileCache(cacheDirectory: _temporaryDirectory());
      await cache.putTile(
        url: _tileUrl,
        metadata: _tileHeader(), // glossary:allow flutter_map API
        bytes: _tileBytes,
      );

      final cached = await cache.getTile(_tileUrl);
      final header = cached!.metadata; // glossary:allow flutter_map API

      expect(cached.bytes, _tileBytes);
      // flutter_map only serves a cached tile without a network request while
      // it is fresh; a stale one triggers a fetch that is unavailable offline.
      expect(header.isStale, isFalse);
    },
  );

  test('returns no tile for a url that was never cached', () async {
    final cache = MapTileCache(cacheDirectory: _temporaryDirectory());
    expect(await cache.getTile(_tileUrl), isNull);
  });

  test('reports a corrupt cached tile as a read failure', () async {
    final directory = _temporaryDirectory();
    final name = base64Url.encode(utf8.encode(_tileUrl));
    File('${directory.path}${Platform.pathSeparator}$name')
        .writeAsStringSync('not a tile');
    final cache = MapTileCache(cacheDirectory: directory);

    await expectLater(
      cache.getTile(_tileUrl),
      throwsA(isA<CachedMapTileReadFailure>()),
    );
  });

  test('degrades to an uncached map when the directory is unusable', () async {
    final blocker = File(
      '${_temporaryDirectory().path}${Platform.pathSeparator}blocker',
    )..writeAsStringSync('not a directory');
    final cache = MapTileCache(
      cacheDirectory: Directory(
        '${blocker.path}${Platform.pathSeparator}tiles',
      ),
    );

    await expectLater(
      cache.putTile(
        url: _tileUrl,
        metadata: _tileHeader(), // glossary:allow flutter_map API
        bytes: _tileBytes,
      ),
      completes,
    );
    expect(await cache.getTile(_tileUrl), isNull);
  });

  test(
    'reads a tile another instance wrote (persists across restarts)',
    () async {
      final directory = _temporaryDirectory();
      await MapTileCache(cacheDirectory: directory).putTile(
        url: _tileUrl,
        metadata: _tileHeader(), // glossary:allow flutter_map API
        bytes: _tileBytes,
      );

      final reopened = MapTileCache(cacheDirectory: directory);

      final cached = await reopened.getTile(_tileUrl);

      expect(cached, isNotNull);
      expect(cached!.bytes, _tileBytes);
    },
  );

  testWidgets('the sites map renders tiles through the persistent cache', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: SitesMap(projectId: 'project-1')),
      ),
    );
    await tester.pumpAndSettle();

    final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(tileLayer.tileProvider, isA<NetworkTileProvider>());
    expect(
      (tileLayer.tileProvider as NetworkTileProvider).cachingProvider,
      isA<MapTileCache>(),
    );
  });
}
