import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Original vector exports from the five Figma frames; files retain root geometry.
class FigmaIcon extends StatelessWidget {
  const FigmaIcon(this.asset, {super.key, required this.size, this.color});
  final String asset;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: SvgPicture.asset(
      'assets/figma/$asset.svg',
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
      excludeFromSemantics: true,
    ),
  );
}

class FigmaScreenTheme extends StatelessWidget {
  const FigmaScreenTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), p = AppPalette.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Inter'),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: p.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          labelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: p.ink,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: p.muted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

class FigmaSegments extends StatelessWidget {
  const FigmaSegments({
    super.key,
    required this.labels,
    required this.selected,
    this.onChanged,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.dark ? p.soft : const Color(0xffebeef2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onChanged == null ? null : () => onChanged!(i),
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: i == selected ? p.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: i == selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: i == selected
                            ? AppTheme.brandInk(context)
                            : p.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
