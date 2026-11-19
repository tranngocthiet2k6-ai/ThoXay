import 'package:flutter/material.dart';

import 'figma_design.dart';

class QrScanSurface extends StatelessWidget {
  const QrScanSurface({
    super.key,
    this.camera,
    this.onTorch,
    this.onGallery,
    this.torchOn = false,
    this.onOpenCamera,
  });
  final Widget? camera;
  final VoidCallback? onTorch, onGallery;
  final bool torchOn;
  final VoidCallback? onOpenCamera;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      height: 378,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff33433c), Color(0xff14211f)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ?camera,
          Align(
            alignment: const Alignment(0, -.82),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xff405049).withValues(alpha: .95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Đưa mã QR vào giữa khung để quét',
                style: TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: IgnorePointer(
              child: FigmaIcon(
                '2c299',
                size: 232,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (onOpenCamera != null)
            Center(
              child: FilledButton.icon(
                onPressed: onOpenCamera,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Mở camera quét QR'),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _control('Đèn pin', '2b64a', onTorch, selected: torchOn),
                _control('Thư viện', 'ac8e8', onGallery),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _control(
    String text,
    String asset,
    VoidCallback? onTap, {
    bool selected = false,
  }) => TextButton.icon(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white54,
      backgroundColor: selected
          ? const Color(0xff6b6044)
          : const Color(0xff405049),
      minimumSize: const Size(106, 44),
      textStyle: const TextStyle(fontSize: 11),
      shape: const StadiumBorder(),
    ),
    onPressed: onTap,
    icon: FigmaIcon(
      asset,
      size: 16,
      color: onTap == null ? Colors.white54 : Colors.white,
    ),
    label: Text(text),
  );
}
