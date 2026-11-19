import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'qr_scan_surface.dart';

class QrCamera extends StatefulWidget {
  const QrCamera({super.key, required this.onCode, this.onGallery});
  final ValueChanged<String> onCode;
  final VoidCallback? onGallery;
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
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<MobileScannerState>(
    valueListenable: _controller,
    builder: (context, state, _) => QrScanSurface(
      onGallery: widget.onGallery,
      torchOn: state.torchState == TorchState.on,
      onTorch: !state.isRunning || state.torchState == TorchState.unavailable
          ? null
          : () async {
              try {
                await _controller.toggleTorch();
              } on MobileScannerException {
                if (mounted) {
                  setState(() => _error = 'Thiết bị không bật được đèn pin.');
                }
              }
            },
      camera: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            )
          : MobileScanner(
              controller: _controller,
              onDetect: (result) {
                for (final barcode in result.barcodes) {
                  if (barcode.rawValue != null) {
                    widget.onCode(barcode.rawValue!);
                    break;
                  }
                }
              },
              errorBuilder: (_, error) => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Camera chưa sẵn sàng. Kiểm tra quyền truy cập hoặc chọn ảnh từ Thư viện.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
    ),
  );
}
