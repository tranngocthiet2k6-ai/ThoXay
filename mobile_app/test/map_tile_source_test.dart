import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/services/map_tile_source.dart';

void main() {
  test(
    'phone browsers and APKs both use the working application tile endpoint',
    () {
      for (final web in [true, false]) {
        final source = MapTileSource(
          isWeb: web,
          apiBaseUrl: 'https://api.example.com/',
        );
        expect(
          source.urlTemplate,
          'https://api.example.com/map-tiles/{z}/{x}/{y}.png',
          reason: 'The mobile web page must not depend on a different tile host than the APK',
        );
        expect(source.headers.containsKey('User-Agent'), !web);
        expect(source.headers.containsKey('Authorization'), isFalse);
        expect(source.headers.containsKey('Cache-Control'), isFalse);
      }
    },
  );
  test('an explicitly configured tile service still takes precedence', () {
    for (final web in [true, false]) {
      expect(
        MapTileSource(
          isWeb: web,
          configuredUrl: 'https://tiles.example.com/{z}/{x}/{y}.png',
        ).urlTemplate,
        'https://tiles.example.com/{z}/{x}/{y}.png',
      );
    }
  });
}
