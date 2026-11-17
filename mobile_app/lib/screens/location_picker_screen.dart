import '../widgets/bouncing_button.dart';
import '../widgets/design_motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../widgets/osm_map_view.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialPosition,
    this.tileProvider,
    this.location,
  });
  final GeoPoint? initialPosition;
  final TileProvider? tileProvider;
  final LocationService? location;
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GeoPoint? _selected = widget.initialPosition;
  bool _locating = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    if (_selected == null) _locate();
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final point = await (widget.location ?? LocationService())
          .currentPosition();
      if (mounted) setState(() => _selected = point);
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chọn vị trí trên bản đồ'),
      actions: [
        IconButton(
          onPressed: _locating ? null : _locate,
          tooltip: 'Lấy vị trí GPS hiện tại',
          icon: const Icon(Icons.my_location),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionIntro(
              title: 'Đặt ghim công trình',
              subtitle: 'Chạm vào vị trí công trình để đặt ghim. Kéo hoặc phóng to bản đồ để chọn chính xác.',
            ),
            const SizedBox(height: 12),
            if (_locating) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('$_error Bạn vẫn có thể chạm bản đồ để đặt ghim.'),
              ),
            Expanded(
              child: OsmMapView(
                center: _selected ?? const GeoPoint(10.7769, 106.7009),
                recenterOnUpdate: true,
                onLocate: _locate,
                tileProvider: widget.tileProvider,
                onTap: (point) => setState(() => _selected = point),
                markers: [
                  if (_selected != null)
                    Marker(
                      point: LatLng(_selected!.latitude, _selected!.longitude),
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 44,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selected == null
                  ? 'Chưa chọn vị trí'
                  : 'Đã chọn: ${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 12),
            BouncingButton(
              child: FilledButton.icon(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.pop(context, _selected),
                icon: const Icon(Icons.check),
                label: const Text('Dùng vị trí đã chọn'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
