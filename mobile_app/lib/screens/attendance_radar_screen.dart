import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/osm_map_view.dart';
import '../widgets/commercial_hero.dart';
import '../widgets/design_motion.dart';
import '../widgets/figma_components.dart';
import '../widgets/app_snack_bar.dart';
import 'shift_scanner_screen.dart';

double attendanceDistance(GeoPoint worker, GeoPoint job) {
  final lat = (job.latitude - worker.latitude) * math.pi / 180;
  final lng = (job.longitude - worker.longitude) * math.pi / 180;
  final a =
      (math.pow(math.sin(lat / 2), 2) +
              math.cos(worker.latitude * math.pi / 180) *
                  math.cos(job.latitude * math.pi / 180) *
                  math.pow(math.sin(lng / 2), 2))
          .clamp(0.0, 1.0);
  return 6371000 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

bool validAttendancePosition(GeoPoint worker, GeoPoint job) =>
    attendanceDistance(worker, job) <= 200 &&
    worker.accuracyMeters != null &&
    worker.accuracyMeters! <= 100;

class AttendanceRadarScreen extends StatefulWidget {
  const AttendanceRadarScreen({
    super.key,
    required this.api,
    required this.job,
    required this.applicationId,
    this.location,
  });
  final ApiService api;
  final Job job;
  final int applicationId;
  final LocationService? location;
  @override
  State<AttendanceRadarScreen> createState() => _AttendanceRadarScreenState();
}

class _AttendanceRadarScreenState extends State<AttendanceRadarScreen> {
  GeoPoint? _point;
  AttendancePage? _data;
  String? _error;
  bool _busy = false;
  late final Timer _ticker;
  DateTime _now = DateTime.now();
  GeoPoint get _site => GeoPoint(widget.job.latitude, widget.job.longitude);
  AttendanceEntry? get _today => _data?.items
      .where(
        (e) =>
            e.day.year == _data!.today.year &&
            e.day.month == _data!.today.month &&
            e.day.day == _data!.today.day,
      )
      .firstOrNull;
  @override
  void initState() {
    super.initState();
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _today != null && _today!.checkedOutAt == null) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final history = await widget.api.attendance(widget.applicationId);
      if (mounted) setState(() => _data = history);
      final p = await (widget.location ?? LocationService()).currentPosition();
      if (mounted) {
        setState(() {
          _point = p;
          _error = null;
        });
      }
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mark({bool qr = false}) async {
    if (_busy) return;
    String? token;
    if (qr) {
      token = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => ShiftScannerScreen(jobId: widget.job.id),
        ),
      );
      if (token == null || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      // A fresh sensor reading accompanies every GPS action; the server decides validity.
      final p = qr
          ? null
          : await (widget.location ?? LocationService()).currentPosition();
      final data = await widget.api.markAttendance(
        widget.applicationId,
        _today != null,
        position: p,
        qrToken: token,
      );
      if (mounted) {
        setState(() {
          _data = data;
          if (p != null) _point = p;
          _error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(
            content: Text('Đã ghi nhận chấm công'),
            kind: NoticeKind.success,
          ),
        );
      }
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = _point, row = _today;
    final valid = point != null && validAttendancePosition(point, _site);
    final done = row?.checkedOutAt != null;
    final duration = row == null
        ? Duration.zero
        : (row.checkedOutAt ?? _now).difference(row.checkedInAt);
    final seconds = duration.inSeconds.clamp(0, 864000);
    final elapsed =
        '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds % 3600 ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar chấm công'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            tooltip: 'Cập nhật GPS',
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 320,
              child: OsmMapView(
                center: _site,
                initialZoom: 17,
                circles: [
                  CircleMarker(
                    point: LatLng(_site.latitude, _site.longitude),
                    radius: 200,
                    useRadiusInMeter: true,
                    color: accent.withValues(alpha: .14),
                    borderColor: accent,
                    borderStrokeWidth: 2,
                  ),
                ],
                markers: [
                  Marker(
                    point: LatLng(_site.latitude, _site.longitude),
                    width: 48,
                    height: 48,
                    child: Icon(Icons.location_on, size: 44, color: accent),
                  ),
                  if (point != null)
                    Marker(
                      point: LatLng(point.latitude, point.longitude),
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xff3b82f6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 12),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CommercialHero(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    point == null
                        ? 'Đang chờ vị trí GPS'
                        : 'Cách ${attendanceDistance(point, _site).round()}m',
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        valid
                            ? Icons.verified_outlined
                            : Icons.location_off_outlined,
                        color: valid
                            ? const Color(0xff6ee7b7)
                            : const Color(0xfffcd34d),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          valid
                              ? 'Trong vùng hợp lệ ≤ 200m'
                              : point == null
                              ? 'Cấp quyền để kiểm tra vị trí'
                              : 'Chưa đạt khoảng cách hoặc độ chính xác GPS',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (point?.accuracyMeters != null)
                    Text(
                      'Sai số cảm biến ±${point!.accuracyMeters!.round()}m',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FigmaCard(
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          done
                              ? 'Ca đã kết thúc'
                              : row == null
                              ? 'Chưa bắt đầu ca'
                              : 'Đang làm việc',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff64748b),
                          ),
                        ),
                        Text(
                          elapsed,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (row != null)
                    const Icon(Icons.check_circle, color: Color(0xff059669)),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy || done || !valid ? null : () => _mark(),
              icon: const Icon(Icons.location_on_outlined),
              label: Text(
                row == null ? 'Chấm công GPS' : 'Kết thúc ca bằng GPS',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy || done ? null : () => _mark(qr: true),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Quét QR ca làm'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Mã ca làm có hiệu lực 5 phút. Server kiểm tra QR và ghi giờ chính thức. Đồng hồ chỉ hiển thị từ thời điểm đã được ghi nhận.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xff64748b),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
