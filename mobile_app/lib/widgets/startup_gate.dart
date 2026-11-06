import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_logo.dart';

/// Shows the brand while startup work and the minimum display time finish.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.builder,
    this.initialize,
    this.onReady,
    this.minimumDuration,
  });

  final WidgetBuilder builder;
  final Future<void> Function()? initialize;
  final VoidCallback? onReady;
  final Duration? minimumDuration;

  // Set by flutter_test_config.dart; timing tests can supply an explicit duration.
  @visibleForTesting
  static Duration? testMinimumDuration;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Timer? _timer;
  bool _elapsed = false;
  bool _ready = false;
  bool _failed = false;
  bool _announced = false;

  @override
  void initState() {
    super.initState();
    final duration =
        widget.minimumDuration ??
        StartupGate.testMinimumDuration ??
        const Duration(milliseconds: 1500);
    _elapsed = duration == Duration.zero;
    if (!_elapsed) {
      _timer = Timer(duration, () {
        if (mounted) setState(() => _elapsed = true);
      });
    }
    _ready = widget.initialize == null;
    if (!_ready) _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _failed = false);
    try {
      await widget.initialize!();
      if (mounted) setState(() => _ready = true);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_elapsed && _ready) {
      if (!_announced) {
        _announced = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onReady?.call();
        });
      }
      return widget.builder(context);
    }
    return SplashScreen(onRetry: _failed ? _initialize : null);
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -.3),
            radius: 1.2,
            colors: [
              dark ? const Color(0xFF1E293B) : const Color(0xFFFFF2E8),
              palette.canvas,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: bounds.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 550),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) =>
                            Opacity(opacity: value, child: child),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BrandLogo(height: 104, onDark: dark),
                            const SizedBox(height: 24),
                            Text(
                              'Kết nối tay nghề, dựng xây uy tín',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: palette.ink, height: 1.5),
                            ),
                            const SizedBox(height: 32),
                            if (onRetry == null)
                              SizedBox(
                                width: 160,
                                child: LinearProgressIndicator(
                                  value: reduceMotion ? .5 : null,
                                  minHeight: 3,
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppTheme.workerOrange,
                                  semanticsLabel: 'Đang khởi động Thợ Xây',
                                ),
                              )
                            else ...[
                              const Text(
                                'Chưa thể khởi động ứng dụng. Vui lòng thử lại.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử lại'),
                              ),
                            ],
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
      ),
    );
  }
}
