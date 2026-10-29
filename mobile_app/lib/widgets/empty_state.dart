import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.icon,
  });
  final String title, message;
  final Widget? action;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffe4ebe7)),
    ),
    child: Column(
      children: [
        ExcludeSemantics(
          child: icon != null
              ? CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(
                    icon,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : CustomPaint(
                  size: const Size(180, 130),
                  painter: _WorksiteIllustration(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class _WorksiteIllustration extends CustomPainter {
  const _WorksiteIllustration(this.accent);
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 130);
    final fill = Paint()..color = accent.withValues(alpha: .09);
    canvas.drawCircle(const Offset(88, 67), 59, fill);
    canvas.drawCircle(
      const Offset(151, 24),
      10,
      fill..color = const Color(0xffffdf9e),
    );
    final line = Paint()
      ..color = accent.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(20, 114), const Offset(163, 114), line);
    canvas.drawLine(const Offset(31, 24), const Offset(31, 112), line);
    canvas.drawLine(const Offset(19, 24), const Offset(144, 24), line);
    canvas.drawLine(const Offset(31, 10), const Offset(31, 24), line);
    canvas.drawLine(const Offset(31, 10), const Offset(94, 24), line);
    canvas.drawLine(const Offset(128, 24), const Offset(128, 53), line);
    canvas.drawArc(const Rect.fromLTWH(122, 48, 12, 14), 0, 2.8, false, line);
    final building = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 40, 54, 74),
      const Radius.circular(6),
    );
    canvas.drawRRect(building, fill..color = Colors.white);
    canvas.drawRRect(building, line);
    for (final x in [62.0, 84.0]) {
      for (final y in [52.0, 72.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 12, 12),
            const Radius.circular(3),
          ),
          fill..color = accent.withValues(alpha: .2),
        );
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(72, 96, 14, 18),
        const Radius.circular(3),
      ),
      fill..color = accent.withValues(alpha: .35),
    );
    final pin = Path()
      ..moveTo(138, 110)
      ..cubicTo(129, 99, 118, 86, 118, 77)
      ..cubicTo(118, 51, 158, 51, 158, 77)
      ..cubicTo(158, 86, 147, 99, 138, 110)
      ..close();
    canvas.drawPath(pin, fill..color = accent);
    canvas.drawCircle(const Offset(138, 77), 7, fill..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WorksiteIllustration oldDelegate) =>
      oldDelegate.accent != accent;
}
