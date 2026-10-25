import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';

class OsmMapView extends StatefulWidget {
  const OsmMapView({
    super.key,
    required this.center,
    this.markers = const [],
    this.fitPoints = const [],
    this.onTap,
    this.tileProvider,
    this.recenterOnUpdate = true,
  });
  final GeoPoint center;
  final List<Marker> markers;
  final List<GeoPoint> fitPoints;
  final ValueChanged<GeoPoint>? onTap;
  final TileProvider? tileProvider;
  final bool recenterOnUpdate;
  @override
  State<OsmMapView> createState() => _OsmMapViewState();
}

class _OsmMapViewState extends State<OsmMapView> {
  static const _tiles = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  final _controller = MapController();
  late final TileProvider _provider =
      widget.tileProvider ?? NetworkTileProvider();
  bool _ready = false, _tileError = false;
  LatLng _latLng(GeoPoint point) => LatLng(
    point.latitude.clamp(-85.05112878, 85.05112878).toDouble(),
    point.longitude,
  );

  @override
  void didUpdateWidget(covariant OsmMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.center.latitude != widget.center.latitude ||
        oldWidget.center.longitude != widget.center.longitude ||
        oldWidget.fitPoints.length != widget.fitPoints.length ||
        List.generate(widget.fitPoints.length, (i) => i).any(
          (i) =>
              oldWidget.fitPoints.length <= i ||
              oldWidget.fitPoints[i].latitude != widget.fitPoints[i].latitude ||
              oldWidget.fitPoints[i].longitude != widget.fitPoints[i].longitude,
        );
    if (_ready && widget.recenterOnUpdate && changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fit();
      });
    }
  }

  void _fit() {
    if (!_ready) return;
    if (widget.fitPoints.isEmpty) {
      _controller.move(_latLng(widget.center), _controller.camera.zoom);
    } else {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([
            _latLng(widget.center),
            ...widget.fitPoints.map(_latLng),
          ]),
          padding: const EdgeInsets.fromLTRB(48, 48, 64, 48),
          maxZoom: 15,
          minZoom: 2,
        ),
      );
    }
  }

  void _zoom(double amount) {
    if (_ready) {
      _controller.move(
        _controller.camera.center,
        (_controller.camera.zoom + amount).clamp(2.0, 19.0).toDouble(),
      );
    }
  }

  void _onTileError() {
    if (_tileError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tileError) setState(() => _tileError = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _latLng(widget.center),
            initialZoom: 13,
            minZoom: 2,
            maxZoom: 19,
            backgroundColor: const Color(0xffe8ede9),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () {
              _ready = true;
              if (widget.fitPoints.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _fit();
                });
              }
            },
            onTap: (_, point) =>
                widget.onTap?.call(GeoPoint(point.latitude, point.longitude)),
          ),
          children: [
            TileLayer(
              urlTemplate: _tiles,
              tileProvider: _provider,
              userAgentPackageName: 'vn.thoxay.tho_xay_mobile',
              maxNativeZoom: 19,
              panBuffer: 0,
              keepBuffer: 1,
              errorTileCallback: (_, error, stackTrace) => _onTileError(),
            ),
            MarkerLayer(markers: widget.markers),
            SimpleAttributionWidget(
              source: const Text('OpenStreetMap contributors'),
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
              ),
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Phóng to bản đồ',
                  onPressed: () => _zoom(1),
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Thu nhỏ bản đồ',
                  onPressed: () => _zoom(-1),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  tooltip: 'Về vùng đang tìm',
                  onPressed: _fit,
                  icon: const Icon(Icons.center_focus_strong),
                ),
              ],
            ),
          ),
        ),
        if (_tileError)
          Positioned(
            top: 8,
            left: 8,
            right: 64,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white.withValues(alpha: .95),
              child: const Text(
                'Chưa tải được nền bản đồ. Kiểm tra mạng; bạn vẫn có thể chọn vị trí hoặc dùng danh sách.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    ),
  );
}
