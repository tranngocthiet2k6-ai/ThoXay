import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

/// A shared sweep for a skeleton group. Respects reduced motion and inactive routes.
class ShimmerSurface extends StatefulWidget {
  const ShimmerSurface({super.key, required this.child, this.label});
  final Widget child;
  final String? label;
  @override
  State<ShimmerSurface> createState() => _ShimmerSurfaceState();
}

class _ShimmerSurfaceState extends State<ShimmerSurface>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _animation.stop();
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    liveRegion: widget.label != null,
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _animation,
            child: widget.child,
            builder: (context, child) => ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) => LinearGradient(
                colors: const [
                  AppColors.transparentWhite,
                  AppColors.whiteMuted,
                  AppColors.transparentWhite,
                ],
                begin: Alignment(-3 + _animation.value * 6, -.3),
                end: Alignment(-1 + _animation.value * 6, .3),
              ).createShader(rect),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });
  final double width, height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppPalette.of(context).skeleton,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class LoadingJobs extends StatelessWidget {
  const LoadingJobs({super.key, this.mapMode = false});
  final bool mapMode;
  @override
  Widget build(BuildContext context) => ShimmerSurface(
    label: mapMode
        ? 'Đang tải bản đồ công trình'
        : 'Đang tải danh sách công trình',
    child: Column(
      children: [
        if (mapMode)
          Container(
            height: 300,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppPalette.of(context).surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                Icons.map_outlined,
                size: 88,
                color: AppPalette.of(context).skeleton,
              ),
            ),
          ),
        for (var i = 0; i < (mapMode ? 1 : 3); i++)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppPalette.of(context).surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 104, height: 28),
                SizedBox(height: 18),
                FractionallySizedBox(
                  widthFactor: .8,
                  child: SkeletonLine(height: 22),
                ),
                SizedBox(height: 14),
                SkeletonLine(width: 154, height: 26),
                SizedBox(height: 18),
                SkeletonLine(),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: .6,
                  child: SkeletonLine(),
                ),
                SizedBox(height: 22),
                SkeletonLine(width: 120, height: 40),
              ],
            ),
          ),
      ],
    ),
  );
}
