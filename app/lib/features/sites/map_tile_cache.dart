import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Name of the directory, under the app support directory, that holds cached
/// map tiles.
const mapTileCacheDirectoryName = 'map_tiles';

/// The header flutter_map stores alongside each cached tile.
typedef _TileHeader = CachedMapTileMetadata; // glossary:allow flutter_map API

/// A persistent, file-backed [MapCachingProvider] for flutter_map tile layers.
///
/// flutter_map 8.2+ routes every tile fetch through a [MapCachingProvider].
/// This one stores each fetched tile on disk under [cacheDirectory] (defaulting
/// to `<application support>/map_tiles`), so tiles viewed while online are
/// served from disk with no connectivity and survive an app restart — the cache
/// holds no in-memory state.
///
/// Cached tiles are treated as fresh for [maxStale] so previously viewed areas
/// keep rendering offline; within that window a tile is served without a
/// network request (flutter_map otherwise reaches for the network, which is
/// unavailable in the field).
class MapTileCache implements MapCachingProvider {
  MapTileCache({
    this.cacheDirectory,
    this.maxStale = const Duration(days: 365),
  });

  /// Directory tiles are stored in, or `null` to resolve the app support
  /// directory lazily on first use.
  final Directory? cacheDirectory;

  /// How long a cached tile is considered fresh.
  final Duration maxStale;

  Directory? _resolved;
  Future<Directory?>? _resolving;

  static const int _headerSeparator = 0x0A;

  @override
  bool get isSupported => true;

  @override
  Future<CachedMapTile?> getTile(String url) async {
    final directory = await _resolveDirectory();
    if (directory == null) return null;

    final file = _fileFor(directory, url);
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsBytes();
      final separator = raw.indexOf(_headerSeparator);
      if (separator < 0) {
        throw const FormatException('cached tile is missing its stored header');
      }
      final stored = jsonDecode(
        utf8.decode(raw.sublist(0, separator)),
      ) as Map<String, Object?>;
      final tileHeader = _TileHeader(
        staleAt: DateTime.parse(stored['staleAt'] as String),
        lastModified: _parseDate(stored['lastModified']),
        etag: stored['etag'] as String?,
      );
      return (
        bytes: Uint8List.sublistView(raw, separator + 1),
        metadata: tileHeader, // glossary:allow flutter_map API
      );
    } catch (error) {
      throw CachedMapTileReadFailure(url: url, originalError: error);
    }
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata, // glossary:allow flutter_map API
    Uint8List? bytes,
  }) async {
    final directory = await _resolveDirectory();
    if (directory == null) return;

    final tileHeader = metadata; // glossary:allow flutter_map API
    final file = _fileFor(directory, url);
    if (bytes == null) {
      // A header-only update (for example a 304): keep the stored bytes.
      if (!await file.exists()) return;
      final stored = await file.readAsBytes();
      final separator = stored.indexOf(_headerSeparator);
      if (separator < 0) return;
      bytes = Uint8List.sublistView(stored, separator + 1);
    }

    final header = utf8.encode(
      jsonEncode(<String, Object?>{
        'staleAt': DateTime.timestamp().add(maxStale).toIso8601String(),
        'lastModified': tileHeader.lastModified?.toUtc().toIso8601String(),
        'etag': tileHeader.etag,
      }),
    );
    final content = BytesBuilder(copy: false)
      ..add(header)
      ..addByte(_headerSeparator)
      ..add(bytes);

    final temporary = File('${file.path}.tmp');
    await temporary.writeAsBytes(content.takeBytes(), flush: true);
    await temporary.rename(file.path);
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  File _fileFor(Directory directory, String url) {
    final name = base64Url.encode(utf8.encode(url));
    return File('${directory.path}${Platform.pathSeparator}$name');
  }

  Future<Directory?> _resolveDirectory() {
    if (_resolved != null) return Future<Directory?>.value(_resolved);
    return _resolving ??= _createDirectory();
  }

  Future<Directory?> _createDirectory() async {
    try {
      final directory = cacheDirectory ?? await _defaultDirectory();
      await directory.create(recursive: true);
      return _resolved = directory;
    } catch (_) {
      // A cache that cannot reach a filesystem degrades to an uncached map
      // rather than breaking tile loading.
      return null;
    }
  }

  static Future<Directory> _defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(
      '${support.path}${Platform.pathSeparator}$mapTileCacheDirectoryName',
    );
  }
}

/// The [MapTileCache] the map uses, resolved on first tile read or write.
final mapTileCacheProvider = Provider<MapTileCache>((ref) => MapTileCache());
