import 'package:flutter/material.dart';

/// A high-contrast anchor shared by home, account and balance surfaces.
class CommercialHero extends StatelessWidget {
  const CommercialHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final accent = base.colorScheme.primary;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xff0f172a),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xff334155)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180f172a),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _GridPainter(accent),
        child: Theme(
          data: base.copyWith(
            textTheme: base.textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            iconTheme: const IconThemeData(color: Color(0xffcbd5e1)),
            dividerColor: Colors.white24,
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.accent);
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    canvas.drawCircle(
      Offset(size.width - 12, 18),
      112,
      Paint()..color = accent.withValues(alpha: .10),
    );
    canvas.drawCircle(
      Offset(size.width - 12, 18),
      78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: .24),
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class PresenceAvatar extends StatelessWidget {
  const PresenceAvatar({
    super.key,
    required this.name,
    this.online,
    this.size = 48,
  });
  final String name;
  final bool? online;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xff1e293b),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: Text(
            name.trim().isEmpty
                ? 'T'
                : name.trim().split(' ').last.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
        if (online != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Semantics(
              label: online! ? 'Sẵn sàng nhận việc' : 'Tạm ngưng nhận việc',
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: online!
                      ? const Color(0xff34d399)
                      : const Color(0xff94a3b8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff0f172a), width: 2),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
