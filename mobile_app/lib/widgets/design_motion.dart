import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reading-width content for secondary routes on desktop, full width on mobile.
class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: child,
    ),
  );
}

class ResponsiveJobGrid extends StatelessWidget {
  const ResponsiveJobGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final columns = bounds.maxWidth >= 820 ? 2 : 1;
      final width = (bounds.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// One-shot viewport reveal. No repeating ticker and no hidden-route work.
class DesignReveal extends StatefulWidget {
  const DesignReveal({super.key, required this.child, this.distance = 18});
  final Widget child;
  final double distance;
  @override
  State<DesignReveal> createState() => _DesignRevealState();
}

class _DesignRevealState extends State<DesignReveal> {
  ScrollPosition? _position;
  bool _visible = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position;
      _position?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _visible) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height && top + box.size.height > 0) {
      setState(() => _visible = true);
      _position?.removeListener(_check);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _visible || reduced ? 1 : 0),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: widget.child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * widget.distance),
          child: child,
        ),
      ),
    );
  }
}

class SectionIntro extends StatelessWidget {
  const SectionIntro({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
  });
  final String title, subtitle;
  final String? eyebrow;
  @override
  Widget build(BuildContext context) => DesignReveal(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppPalette.of(context).muted),
          ),
        ],
      ),
    ),
  );
}

/// A pointer-following accent, kept to a small painted layer; no blur or ticker.
class DesignSurface extends StatefulWidget {
  const DesignSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.dark = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool dark;
  @override
  State<DesignSurface> createState() => _DesignSurfaceState();
}

class _DesignSurfaceState extends State<DesignSurface> {
  bool _hover = false;
  Alignment _light = Alignment.topRight;
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _light = Alignment.topRight;
      }),
      onHover: reduced
          ? null
          : (event) {
              final box = context.findRenderObject();
              if (box is RenderBox &&
                  box.hasSize &&
                  box.size.width > 0 &&
                  box.size.height > 0) {
                final next = Alignment(
                  2 * event.localPosition.dx / box.size.width - 1,
                  2 * event.localPosition.dy / box.size.height - 1,
                );
                if ((_light.x - next.x).abs() + (_light.y - next.y).abs() >
                    .15) {
                  setState(() => _light = next);
                }
              }
            },
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
        clipBehavior: Clip.antiAlias,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.dark ? AppColors.ink : AppPalette.of(context).surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: AppPalette.of(context).outdoor ? 2 : 1,
            color: _hover
                ? primary.withValues(alpha: .4)
                : widget.dark
                ? AppColors.ink
                : AppPalette.of(context).border,
          ),
          gradient: AppPalette.of(context).outdoor && !widget.dark
              ? null
              : RadialGradient(
                  center: _light,
                  radius: 1.6,
                  colors: widget.dark
                      ? [
                          Color.alphaBlend(
                            primary.withValues(alpha: .22),
                            AppColors.ink,
                          ),
                          AppColors.ink,
                        ]
                      : [
                          Color.alphaBlend(
                            primary.withValues(alpha: _hover ? .06 : .015),
                            AppPalette.of(context).surface,
                          ),
                          AppPalette.of(context).surface,
                        ],
                ),
          boxShadow: AppPalette.of(context).outdoor
              ? []
              : [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: _hover ? .07 : .025),
                    blurRadius: _hover ? 28 : 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Scroll-linked background detail. Static on compact/reduced-motion layouts.
class ConstructionArtwork extends StatelessWidget {
  const ConstructionArtwork({super.key, this.height = 180});
  final double height;
  @override
  Widget build(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.sizeOf(context).width < 600;
    final artwork = ExcludeSemantics(
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _ConstructionPainter(Theme.of(context).colorScheme.primary),
      ),
    );
    if (position == null || reduced) return artwork;
    return ListenableBuilder(
      listenable: position,
      child: artwork,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (-position.pixels * .045).clamp(-14.0, 14.0)),
        child: child,
      ),
    );
  }
}

class _ConstructionPainter extends CustomPainter {
  const _ConstructionPainter(this.accent);
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 340, size.height / 180);
    final fill = Paint()..color = AppColors.surface.withValues(alpha: .06);
    final line = Paint()
      ..color = AppColors.surface.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var x = 20.0; x < 340; x += 24) {
      for (var y = 8.0; y < 180; y += 24) {
        canvas.drawCircle(Offset(x, y), 1, fill);
      }
    }
    canvas.drawLine(const Offset(12, 160), const Offset(328, 160), line);
    for (final rect in [
      const Rect.fromLTWH(64, 70, 65, 90),
      const Rect.fromLTWH(139, 36, 83, 124),
      const Rect.fromLTWH(232, 101, 47, 59),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        line,
      );
      for (var x = rect.left + 13; x < rect.right - 8; x += 20) {
        for (var y = rect.top + 16; y < rect.bottom - 12; y += 22) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, 6, 8),
            Paint()..color = accent.withValues(alpha: .8),
          );
        }
      }
    }
    final crane = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(37, 20), const Offset(37, 160), crane);
    canvas.drawLine(const Offset(18, 28), const Offset(292, 28), crane);
    canvas.drawLine(const Offset(37, 6), const Offset(126, 28), crane);
    canvas.drawLine(const Offset(274, 28), const Offset(274, 70), crane);
    canvas.drawArc(const Rect.fromLTWH(267, 65, 14, 14), 0, 2.9, false, crane);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ConstructionPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
