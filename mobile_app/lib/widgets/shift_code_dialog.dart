import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/attendance.dart';
import '../services/api_service.dart';

class ShiftCodeDialog extends StatefulWidget {
  const ShiftCodeDialog({super.key, required this.api, required this.jobId});
  final ApiService api;
  final int jobId;
  @override
  State<ShiftCodeDialog> createState() => _ShiftCodeDialogState();
}

class _ShiftCodeDialogState extends State<ShiftCodeDialog> {
  ShiftCode? _code;
  String? _error;
  bool _loading = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = await widget.api.shiftCode(widget.jobId);
      if (mounted) setState(() => _code = code);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        _code?.expiresAt.difference(DateTime.now()).inSeconds ?? 0;
    return AlertDialog(
      title: const Text('QR ca làm tại công trường'),
      scrollable: true,
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!),
            if (_code != null && remaining > 0) ...[
              QrImageView(
                data: _code!.qr,
                size: 260,
                backgroundColor: Colors.white,
              ),
              Text(
                'Còn ${remaining ~/ 60} phút ${remaining % 60} giây',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Thợ quét mã để check-in hoặc check-out. Chỉ chia sẻ tại công trường.',
                textAlign: TextAlign.center,
              ),
              TextButton.icon(
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: _code!.token)),
                icon: const Icon(Icons.copy),
                label: const Text('Sao chép mã nhập tay'),
              ),
            ] else if (_code != null)
              const Text('Mã đã hết hạn. Tạo mã mới để tiếp tục.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: _loading ? null : _load,
          child: const Text('Tạo mã mới'),
        ),
      ],
    );
  }
}
