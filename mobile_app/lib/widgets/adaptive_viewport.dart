import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared desktop frame. Local MediaQuery matches the navigator's real width.
class AdaptiveViewport extends StatelessWidget {
  const AdaptiveViewport({super.key, required this.child});
  final Widget child;
  static const maxWidth = 1120.0;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final width = math.min(bounds.maxWidth, maxWidth);
      return ColoredBox(
        color: AppColors.canvas,
        child: Center(
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(size: Size(width, bounds.maxHeight)),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

abstract final class AppSpacing {
  static const small = 8.0;
  static const gap = 16.0;
  static const section = 24.0;
  static const radius = 16.0;
  static const muted = Color(0xff64748b);
}
