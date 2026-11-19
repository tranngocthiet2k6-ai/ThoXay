import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'figma_components.dart';
import 'figma_design.dart';

class QrGpsStatus extends StatefulWidget {
  const QrGpsStatus({super.key, this.location});
  final LocationService? location;
  @override
  State<QrGpsStatus> createState() => _QrGpsStatusState();
}

class _QrGpsStatusState extends State<QrGpsStatus> {
  bool _ready = false, _busy = false;
  String? _error;
  Future<void> _check() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.location ?? LocationService()).currentPosition();
      if (mounted) {
        setState(() => _ready = true);
      }
    } on LocationFailure catch (e) {
      if (mounted) {
        setState(() {
          _ready = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = false;
          _error = 'Chưa lấy được GPS. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return FigmaCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: _busy ? null : _check,
        leading: FigmaIcon(
          'f4474',
          size: 22,
          color: _ready ? palette.successStrong : palette.muted,
        ),
        title: Text(
          _ready
              ? 'GPS đã bật · Sẵn sàng điểm danh'
              : _busy
              ? 'Đang kiểm tra GPS…'
              : 'Bật GPS để sẵn sàng điểm danh',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _ready ? palette.successStrong : palette.ink,
          ),
        ),
        subtitle: Text(
          _error ??
              (_ready
                  ? 'Vị trí sẽ được kiểm tra lại khi chấm công trong 200m.'
                  : 'Chạm để kiểm tra quyền và vị trí hiện tại.'),
          style: TextStyle(fontSize: 10, color: palette.muted),
        ),
      ),
    );
  }
}
