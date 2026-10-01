import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/app_config.dart';

void main() {
  group('resolveApiBaseUrl', () {
    test('uses the configured IBIS_API_BASE_URL when it is defined', () {
      expect(
        resolveApiBaseUrl(
          configured: 'https://api.example.com',
          release: false,
        ),
        'https://api.example.com',
      );
    });

    test('falls back to the localhost default when undefined outside a release build', () {
      expect(
        resolveApiBaseUrl(configured: '', release: false),
        'http://localhost:3000',
      );
    });

    test('throws when undefined in a release build instead of using the localhost default', () {
      expect(
        () => resolveApiBaseUrl(configured: '', release: true),
        throwsStateError,
      );
    });

    test('still uses the configured value in a release build', () {
      expect(
        resolveApiBaseUrl(configured: 'https://api.example.com', release: true),
        'https://api.example.com',
      );
    });
  });

  test('apiBaseUrl is the value every client is constructed from', () {
    expect(apiBaseUrl, defaultApiBaseUrl);
  });
}
