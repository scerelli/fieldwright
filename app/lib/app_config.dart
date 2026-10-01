/// The one compile-time value naming the server root. Pass it at build/run time
/// with `--dart-define=IBIS_API_BASE_URL=<url>`; the name is fixed so the local
/// host, the Android emulator and production all use one knob.
const String ibisApiBaseUrlName = 'IBIS_API_BASE_URL';

/// The value compiled in at build time, empty when `IBIS_API_BASE_URL` was not
/// passed. Read through [resolveApiBaseUrl], never directly.
const String _ibisApiBaseUrl = String.fromEnvironment(ibisApiBaseUrlName);

/// Local default: correct for a host-run API reached from the iOS simulator or
/// desktop. Wrong inside the Android emulator, whose host loopback is
/// `10.0.2.2`, so an emulator run must define `IBIS_API_BASE_URL` explicitly.
const String defaultApiBaseUrl = 'http://localhost:3000';

/// True in a `--release` (product) build; false in debug and in tests.
const bool isReleaseBuild = bool.fromEnvironment('dart.vm.product');

/// Resolves the server root. [configured] and [release] default to the
/// compile-time values so callers just call `resolveApiBaseUrl()`; tests pass
/// them explicitly.
///
/// A release build with no [configured] value throws instead of silently
/// pointing at the localhost default.
String resolveApiBaseUrl({
  String configured = _ibisApiBaseUrl,
  bool release = isReleaseBuild,
}) {
  if (configured.isNotEmpty) return configured;
  if (release) {
    throw StateError(
      '$ibisApiBaseUrlName is not set. A release build must pass '
      '--dart-define=$ibisApiBaseUrlName=<server>; refusing to fall back to '
      '$defaultApiBaseUrl.',
    );
  }
  return defaultApiBaseUrl;
}

/// The server root, resolved once from [ibisApiBaseUrlName]. Every client is
/// constructed from this one value.
final String apiBaseUrl = resolveApiBaseUrl();
