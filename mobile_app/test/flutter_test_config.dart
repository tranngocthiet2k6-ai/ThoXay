import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tho_xay_mobile/widgets/osm_map_view.dart';
import 'package:tho_xay_mobile/widgets/startup_gate.dart';

class _MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Home/detail previews now contain maps as well as the dedicated map screens.
  // Every widget test stays offline; no OSM tile requests are made by default.
  setUp(() {
    OsmMapView.testTileProviderFactory = _MemoryTiles.new;
    StartupGate.testMinimumDuration = Duration.zero;
  });
  tearDown(() {
    OsmMapView.testTileProviderFactory = null;
    StartupGate.testMinimumDuration = null;
  });
  await testMain();
}
