import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'bouncing_button.dart';

class GradientPrimaryButton extends StatelessWidget {
  const GradientPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
  });
  final VoidCallback? onPressed;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final enabled = onPressed != null;
    final blue =
        Theme.of(context).colorScheme.primary == AppTheme.contractorBlue;
    return BouncingButton(
      enabled: enabled,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: !enabled
                ? [palette.border, palette.border]
                : palette.outdoor
                ? [Colors.black, Colors.black]
                : blue
                ? const [AppTheme.contractorBlue, Color(0xff1e40af)]
                : const [AppTheme.workerAmber, Color(0xfff59e0b)],
          ),
          boxShadow: enabled && !palette.outdoor
              ? [
                  BoxShadow(
                    color:
                        (blue ? AppTheme.contractorBlue : AppTheme.workerAmber)
                            .withValues(alpha: .20),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            foregroundColor: palette.outdoor || blue
                ? Colors.white
                : const Color(0xff241400),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientProgress extends StatelessWidget {
  const GradientProgress({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
  });
  final double value, height;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (_, progress, _) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: height,
            child: ColoredBox(
              color: AppPalette.of(context).border,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          Color.lerp(accent, const Color(0xFFFBBF24), .45)!,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final palette = AppPalette.of(context);
      final reduced = MediaQuery.disableAnimationsOf(context);
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: palette.soft,
          borderRadius: BorderRadius.circular(28),
          border: palette.outdoor
              ? Border.all(color: palette.border, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: Alignment(
                labels.length == 1
                    ? 0
                    : -1 + 2 * selected / (labels.length - 1),
                0,
              ),
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Container(
                width: (bounds.maxWidth - 10) / labels.length,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: palette.outdoor
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x160F172A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: selected == i,
                      button: true,
                      child: BouncingButton(
                        child: TextButton(
                          onPressed: () {
                            AppHaptics.light();
                            onChanged(i);
                          },
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            foregroundColor: selected == i
                                ? Colors.white
                                : palette.muted,
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// Finite radar sweep: remains calm after discovery and respects reduced motion.
class RadarPulse extends StatelessWidget {
  const RadarPulse({super.key, required this.child, this.size = 72});
  final Widget child;
  final double size;
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1800),
      builder: (_, phase, child) => Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: size * (.55 + phase * .4 - i * .12),
              height: size * (.55 + phase * .4 - i * .12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: .03),
                border: Border.all(
                  color: accent.withValues(alpha: .28 - phase * .12),
                ),
              ),
            ),
          child!,
        ],
      ),
      child: child,
    );
  }
}
