import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCamera extends StatefulWidget {
  const QrCamera({super.key, required this.onCode});
  final ValueChanged<String> onCode;
  @override
  State<QrCamera> createState() => _QrCameraState();
}

class _QrCameraState extends State<QrCamera> with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    try {
      await _controller.start();
    } on MobileScannerException {
      if (mounted) {
        setState(
          () => _error = 'Chưa mở được camera. Cho phép quyền camera trong cài đặt ứng dụng/trình duyệt rồi thử lại.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_controller.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: MobileScanner(
            controller: _controller,
            onDetect: (result) {
              for (final barcode in result.barcodes) {
                if (barcode.rawValue != null) {
                  widget.onCode(barcode.rawValue!);
                  break;
                }
              }
            },
            errorBuilder: (_, error) => const ColoredBox(
              color: Color(0xff0f172a),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Camera chưa sẵn sàng. Kiểm tra quyền truy cập hoặc dán nội dung mã QR.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_error == null)
          IgnorePointer(
            child: Container(
              width: 216,
              height: 216,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        if (_error != null)
          ColoredBox(
            color: const Color(0xff0f172a),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      setState(() => _error = null);
                      _start();
                    },
                    child: const Text('Thử lại camera'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
