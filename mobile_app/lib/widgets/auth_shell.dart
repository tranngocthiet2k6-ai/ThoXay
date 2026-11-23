import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'appearance_button.dart';
import 'brand_logo.dart';
import 'figma_design.dart';
import 'server_connection_notice.dart';

const _authDuration = Duration(milliseconds: 250);

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.api,
    required this.scrollController,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.selectedTab,
    required this.revision,
    required this.forward,
    required this.onTabChanged,
  });
  final ApiService api;
  final ScrollController scrollController;
  final String title, subtitle;
  final Widget child;
  final int selectedTab, revision;
  final bool forward;
  final ValueChanged<int>? onTabChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _authDuration;
    final contentKey = ValueKey('auth-content-$revision');
    return FigmaScreenTheme(
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            BrandLogo(height: 76),
                            Spacer(),
                            AppearanceButton(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AuthTabs(
                          selected: selectedTab,
                          onChanged: onTabChanged,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('auth-scroll'),
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ServerConnectionNotice(api: api),
                          AnimatedSize(
                            // A zero resize duration causes synchronous layout
                            // invalidation in RenderAnimatedSize. Keep this
                            // imperceptible while fade/slide are fully skipped.
                            duration: duration == Duration.zero
                                ? const Duration(milliseconds: 1)
                                : duration,
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: duration,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              // Only the incoming form determines height.
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  for (final old in previous)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: old,
                                    ),
                                  ?current,
                                ],
                              ),
                              transitionBuilder: (child, animation) {
                                final incoming = child.key == contentKey;
                                final direction = forward ? 1.0 : -1.0;
                                return IgnorePointer(
                                  ignoring: !incoming,
                                  child: ExcludeSemantics(
                                    excluding: !incoming,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: Offset(
                                            (incoming
                                                    ? direction
                                                    : -direction) *
                                                .10,
                                            0,
                                          ),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                key: contentKey,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: p.ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 21,
                                      height: 1.3,
                                      letterSpacing: -.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: p.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  child,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tiếp tục là bạn đồng ý với Điều khoản & Bảo mật.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: p.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single sliding indicator, independent of the animated form below it.
class AuthTabs extends StatelessWidget {
  const AuthTabs({super.key, required this.selected, this.onChanged});
  final int selected;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _authDuration;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.dark ? p.soft : const Color(0xffebeef2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                key: const ValueKey('auth-tab-indicator'),
                alignment: selected == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: .5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: selected == i,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: onChanged == null ? null : () => onChanged!(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            child: Text(
                              i == 0 ? 'Đăng nhập' : 'Đăng ký',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: selected == i
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selected == i
                                    ? AppTheme.brandInk(context)
                                    : p.muted,
                              ),
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
      ),
    );
  }
}
