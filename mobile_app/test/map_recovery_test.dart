import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/osm_map_view.dart';

import 'maps_test.dart' show settleMap;

class _FailedTile extends ImageProvider<_FailedTile> {
  @override
  Future<_FailedTile> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _FailedTile key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(
      StateError('Simulated temporary tile connection failure'),
    ),
  );
}

class _RecoveringTiles extends TileProvider {
  bool failing = true;
  int requests = 0;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    requests++;
    return failing ? _FailedTile() : MemoryImage(TileProvider.transparentImage);
  }
}

void main() {
  testWidgets(
    'web and native maps use the same reachable API origin and keep tile caching',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 380,
              child: OsmMapView(
                center: const GeoPoint(10.7769, 106.7009),
                tileProvider: _RecoveringTiles()..failing = false,
              ),
            ),
          ),
        ),
      );
      await settleMap(tester);
      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(
        layer.urlTemplate,
        '${ApiService.defaultBaseUrl}/map-tiles/{z}/{x}/{y}.png',
      );
      expect(layer.fallbackUrl, isNull);
      expect(find.text('OpenStreetMap contributors'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  Future<void> openMap(WidgetTester tester, _RecoveringTiles tiles) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 380,
            child: OsmMapView(
              center: const GeoPoint(10.7769, 106.7009),
              tileProvider: tiles,
            ),
          ),
        ),
      ),
    );
    await settleMap(tester);
  }

  testWidgets('retry requests tiles again and keeps attribution visible', (
    tester,
  ) async {
    final tiles = _RecoveringTiles();
    await openMap(tester, tiles);
    final failedRequests = tiles.requests;
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    tiles.failing = false;
    await tester.tap(find.text('Thử lại'));
    await settleMap(tester);
    expect(tiles.requests, greaterThan(failedRequests));
    expect(find.textContaining('Chưa tải được nền bản đồ'), findsNothing);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('returning to the app retries a failed map automatically', (
    tester,
  ) async {
    final tiles = _RecoveringTiles();
    await openMap(tester, tiles);
    final failedRequests = tiles.requests;
    tiles.failing = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settleMap(tester);
    expect(tiles.requests, greaterThan(failedRequests));
    expect(find.textContaining('Chưa tải được nền bản đồ'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a successful map load clears a previous connection warning', (
    tester,
  ) async {
    final tiles = _RecoveringTiles();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 380,
            child: OsmMapView(
              center: const GeoPoint(10.7769, 106.7009),
              tileProvider: tiles,
            ),
          ),
        ),
      ),
    );
    await settleMap(tester);
    expect(find.textContaining('Chưa tải được nền bản đồ'), findsOneWidget);
    tiles.failing = false;
    await tester.tap(find.byTooltip('Phóng to bản đồ'));
    await settleMap(tester);
    expect(find.textContaining('Chưa tải được nền bản đồ'), findsNothing);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
