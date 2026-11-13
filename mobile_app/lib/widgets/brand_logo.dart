import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Vector helmet only. No wordmark; stays crisp at splash and toolbar sizes.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 40, this.onDark = false});
  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Thợ Xây · Mũ bảo hộ',
    image: true,
    child: SizedBox(
      height: height,
      width: height * 1.6,
      child: const CustomPaint(painter: _HelmetPainter()),
    ),
  );
}

class _HelmetPainter extends CustomPainter {
  const _HelmetPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 75);
    final paint = Paint()
      ..color = AppTheme.workerAmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(19, 54)
        ..cubicTo(23, 32, 31, 20, 45, 18),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(75, 18)
        ..cubicTo(89, 20, 98, 32, 101, 54),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(48, 40)
        ..lineTo(43, 12)
        ..quadraticBezierTo(60, 5, 77, 12)
        ..lineTo(72, 40),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(8, 64)
        ..quadraticBezierTo(60, 46, 112, 64),
      paint..strokeWidth = 8,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HelmetPainter oldDelegate) => false;
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Semantics(label: '$title · Thợ Xây', child: const BrandLogo(height: 32));
}
