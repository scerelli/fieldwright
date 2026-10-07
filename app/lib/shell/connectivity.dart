import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The injectable seam over the device's network transport state (ADR-0022).
///
/// A fake is used in tests, so no platform channel is touched. It reports the
/// transport type, not internet reachability: no transport means no connection,
/// but a reported transport is no guarantee a request reaches the server, so
/// network code stays guarded by timeouts and errors.
abstract interface class ConnectivitySource {
  /// Whether the device currently has no network transport.
  Future<bool> isOffline();

  /// Emits whenever the device's offline state changes; true means no transport.
  Stream<bool> get offlineChanges;
}

/// Whether a `connectivity_plus` transport result means there is no connection.
///
/// The plugin reports no transport as an empty list or a single
/// [ConnectivityResult.none]; any real transport — including one listed
/// alongside `none` — counts as connected (ADR-0022). Pure so it is unit
/// testable without a platform channel.
bool hasNoConnection(List<ConnectivityResult> results) =>
    results.isEmpty ||
    results.every((result) => result == ConnectivityResult.none);

/// The production [ConnectivitySource], backed by `connectivity_plus`
/// (TECH_STACK.md, ADR-0022). The plugin reports no transport as a single
/// [ConnectivityResult.none], or an empty list.
class DeviceConnectivitySource implements ConnectivitySource {
  DeviceConnectivitySource({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOffline() async =>
      hasNoConnection(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get offlineChanges =>
      _connectivity.onConnectivityChanged.map(hasNoConnection);
}

/// The device connectivity source used by the running app. Tests override this
/// with a fake so no platform channel is touched.
final connectivitySourceProvider = Provider<ConnectivitySource>(
  (ref) => DeviceConnectivitySource(),
);

/// The current offline state: seeded by a transport check, then kept live by
/// the transport-change stream. A read that errors — a missing platform plugin
/// in a test, for example — surfaces as an `AsyncError`, which the shell reads
/// as "online" through its `.value ?? false` (ADR-0022).
final offlineProvider = StreamProvider<bool>((ref) async* {
  final source = ref.watch(connectivitySourceProvider);
  yield await source.isOffline();
  yield* source.offlineChanges;
});
