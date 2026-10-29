import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

import '../services/kyc_camera.dart';

class KycScannerFrame extends StatelessWidget {
  const KycScannerFrame({super.key, required this.label, this.photo});
  final String label;
  final KycPhoto? photo;
  void _preview(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.ink,
        appBar: AppBar(
          title: Text(label),
          leading: IconButton(
            tooltip: 'Đóng ảnh phóng to',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chụm hai ngón hoặc cuộn để phóng to và kéo để đối chiếu.',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.memory(
                    photo!.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text(
                      'Không xem được ảnh, hãy chụp lại.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Semantics(
        label: photo == null ? 'Khung hướng dẫn $label' : 'Phóng to $label',
        button: photo != null,
        child: InkWell(
          onTap: photo == null ? null : () => _preview(context),
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 85.6 / 53.98,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: AppColors.slateLight,
                    child: photo == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 56,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Giữ đủ 4 góc thẻ trong khung',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Image.memory(
                            photo!.bytes,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Center(
                              child: Text('Không xem được ảnh, hãy chụp lại.'),
                            ),
                          ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _FramePainter(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (photo != null)
                  const Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.zoom_in, color: AppColors.ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final c in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final dx = c.dx == 0 ? 1.0 : -1.0, dy = c.dy == 0 ? 1.0 : -1.0;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + dx * 28, c.dy + dy * 3)
          ..lineTo(c.dx + dx * 3, c.dy + dy * 3)
          ..lineTo(c.dx + dx * 3, c.dy + dy * 28),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) =>
      oldDelegate.color != color;
}
