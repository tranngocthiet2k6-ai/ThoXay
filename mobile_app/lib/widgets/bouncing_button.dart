import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Observes pointer feedback without claiming gestures from buttons or scrolls.
/// The child keeps keyboard focus, semantics, disabled state and its one action.
class BouncingButton extends StatefulWidget {
  const BouncingButton({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> {
  int? _pointer;
  Offset? _origin;
  bool _pressed = false;
  bool get _enabled {
    final child = widget.child;
    return widget.enabled &&
        (child is! ButtonStyleButton ||
            child.onPressed != null ||
            child.onLongPress != null);
  }

  void _release() {
    _pointer = null;
    _origin = null;
    if (_pressed && mounted) setState(() => _pressed = false);
  }

  @override
  void didUpdateWidget(covariant BouncingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _pointer = null;
      _origin = null;
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (event) {
        if (!_enabled || _pointer != null || event.buttons != kPrimaryButton) {
          return;
        }
        _pointer = event.pointer;
        _origin = event.position;
        setState(() => _pressed = true);
      },
      onPointerMove: (event) {
        if (event.pointer == _pointer &&
            (event.position - _origin!).distance > kTouchSlop) {
          _release();
        }
      },
      onPointerUp: (event) {
        if (event.pointer == _pointer) _release();
      },
      onPointerCancel: (event) {
        if (event.pointer == _pointer) _release();
      },
      child: AnimatedScale(
        scale: _pressed && !reduced ? .96 : 1,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 120),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

abstract final class AppHaptics {
  /// A missing desktop/browser haptics implementation must not block an action.
  static void light() => unawaited(_light());
  static Future<void> _light() async {
    try {
      await HapticFeedback.lightImpact();
    } on Object {
      /* Optional hardware. */
    }
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
