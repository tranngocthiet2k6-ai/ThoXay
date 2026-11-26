import 'dart:async';

import '../theme/app_theme.dart';
import '../services/map_tile_client.dart';
import '../services/api_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import 'loading_jobs.dart';
import 'app_snack_bar.dart';

class OsmMapView extends StatefulWidget {
  @visibleForTesting
  static TileProvider Function()? testTileProviderFactory;
  const OsmMapView({
    super.key,
    required this.center,
    this.markers = const [],
    this.fitPoints = const [],
    this.onTap,
    this.tileProvider,
    this.recenterOnUpdate = true,
    this.interactive = true,
    this.circles = const [],
    this.initialZoom = 13,
    this.onLocate,
  });
  final GeoPoint center;
  final List<Marker> markers;
  final List<GeoPoint> fitPoints;
  final ValueChanged<GeoPoint>? onTap;
  final TileProvider? tileProvider;
  final bool recenterOnUpdate;
  final bool interactive;
  final List<CircleMarker> circles;
  final double initialZoom;
  final Future<void> Function()? onLocate;
  @override
  State<OsmMapView> createState() => _OsmMapViewState();
}

class _OsmMapViewState extends State<OsmMapView> with WidgetsBindingObserver {
  static const _configuredTiles = String.fromEnvironment('MAP_TILE_URL');
  static String get _tiles => _configuredTiles.isNotEmpty
      ? _configuredTiles
      : kIsWeb
      ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
      : '${ApiService.defaultBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/map-tiles/{z}/{x}/{y}.png';
  final _controller = MapController();
  late final TileProvider _provider;
  MapTileClient? _tileClient;
  bool _ready = false, _tileError = false;
  String _tileErrorDetail = '';
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final injected =
        widget.tileProvider ?? OsmMapView.testTileProviderFactory?.call();
    if (injected != null) {
      _provider = injected;
    } else {
      _tileClient = MapTileClient();
      _provider = NetworkTileProvider(
        httpClient: _tileClient,
        headers: kIsWeb
            ? {}
            : {
                'User-Agent': 'ThoXay (vn.thoxay.tho_xay_mobile; https://thoxay.vercel.app)',
              },
        attemptDecodeOfHttpErrorResponses: false,
      );
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tileError) _retryTiles();
  }

  void _retryTiles() {
    setState(() => _tileError = false);
    _tileReset.add(null);
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (widget.onLocate != null) {
        await widget.onLocate!();
      } else {
        final point = await LocationService().currentPosition();
        if (mounted && _ready) {
          _controller.move(_latLng(point), _controller.camera.zoom);
        }
      }
    } on LocationFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  final _tileReset = StreamController<void>.broadcast();
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

  String _describeTileError(Object error) {
    if (error is NetworkImageLoadException) {
      if (error.statusCode == 429) {
        return 'Nguồn bản đồ đang giới hạn lượt tải. Vui lòng thử lại sau.';
      }
      return 'Nguồn bản đồ trả lỗi HTTP ${error.statusCode}. Vui lòng thử lại sau.';
    }
    final detail = error.toString().toLowerCase();
    if (detail.contains('handshake') || detail.contains('certificate')) {
      return 'Không xác minh được kết nối bảo mật tới nguồn bản đồ. Kiểm tra ngày giờ thiết bị.';
    }
    if (detail.contains('failed host lookup') ||
        detail.contains('name resolution')) {
      return 'Không tìm thấy máy chủ bản đồ. Thử kết nối Wi-Fi hoặc 4G khác.';
    }
    return 'Kiểm tra mạng; bạn vẫn có thể chọn vị trí hoặc dùng danh sách.';
  }

  void _onTileError(Object error) {
    if (_tileError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tileError) {
        setState(() {
          _tileError = true;
          _tileErrorDetail = _describeTileError(error);
        });
      }
    });
  }

  void _onTileLoaded() {
    if (!_tileError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tileError) setState(() => _tileError = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tileClient?.close();
    _controller.dispose();
    unawaited(_tileReset.close());
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
            initialZoom: widget.initialZoom,
            minZoom: 2,
            maxZoom: 19,
            backgroundColor: AppPalette.of(context).soft,
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
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
              reset: _tileReset.stream,
              urlTemplate: _tiles,
              tileProvider: _provider,
              userAgentPackageName: 'vn.thoxay.tho_xay_mobile',
              maxNativeZoom: 19,
              panBuffer: 0,
              keepBuffer: 1,
              tileBuilder: (context, image, tile) {
                if (!tile.loadError && tile.imageInfo != null) _onTileLoaded();
                return _provider is NetworkTileProvider &&
                        tile.loadStarted != null &&
                        tile.loadFinishedAt == null &&
                        !tile.loadError &&
                        !tile.cancelLoading.isCompleted
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ShimmerSurface(
                            child: ColoredBox(
                              color: AppPalette.of(context).soft,
                            ),
                          ),
                          image,
                        ],
                      )
                    : image;
              },
              errorTileCallback: (_, error, stackTrace) => _onTileError(error),
            ),
            if (widget.circles.isNotEmpty) CircleLayer(circles: widget.circles),
            MarkerLayer(markers: widget.markers),
            Align(
              alignment: Alignment.bottomRight,
              child: Material(
                color: Colors.white.withValues(alpha: .94),
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      children: [
                        Text(
                          '© ',
                          style: TextStyle(color: Colors.black, fontSize: 10),
                        ),
                        Text(
                          'OpenStreetMap contributors',
                          style: TextStyle(color: Colors.black, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.interactive)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: AppPalette.of(context).surface,
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
                    tooltip: 'Vị trí GPS hiện tại',
                    onPressed: _locating ? null : _locate,
                    icon: const Icon(Icons.my_location),
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
            right: widget.interactive ? 64 : 8,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: AppPalette.of(context).surface.withValues(alpha: .95),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chưa tải được nền bản đồ. $_tileErrorDetail',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _retryTiles,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
