import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/attendance.dart';

class ShiftScannerScreen extends StatefulWidget {
  const ShiftScannerScreen({super.key, required this.jobId});
  final int jobId;
  @override
  State<ShiftScannerScreen> createState() => _ShiftScannerScreenState();
}

class _ShiftScannerScreenState extends State<ShiftScannerScreen> {
  bool _done = false;
  String? _error;
  void _detect(BarcodeCapture result) {
    if (_done) return;
    for (final barcode in result.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final token = ShiftCode.parse(raw, widget.jobId);
      if (token != null) {
        _done = true;
        Navigator.pop(context, token);
        return;
      }
      if (_error == null) {
        setState(
          () => _error = 'Mã này không thuộc ca làm của công trình đang chọn.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quét QR ca làm')),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          onDetect: _detect,
          errorBuilder: (context, error) => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Không mở được camera. Cho phép truy cập camera hoặc quay lại để nhập mã ca làm.',
              ),
            ),
          ),
        ),
        Center(
          child: IgnorePointer(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error ?? 'Đưa mã QR chủ thầu cung cấp vào khung. Mã có hiệu lực 5 phút.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
