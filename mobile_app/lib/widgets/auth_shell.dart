import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'appearance_button.dart';
import 'brand_logo.dart';
import 'figma_design.dart';
import 'server_connection_notice.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.canGoBack = false,
    this.api,
    this.roleSelection,
    this.onRegister,
  });
  final String title, subtitle;
  final Widget child;
  final bool canGoBack;
  final ApiService? api;
  final Widget? roleSelection;
  final VoidCallback? onRegister;
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return FigmaScreenTheme(
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: MediaQuery.sizeOf(context).width < 600
                ? Alignment.topCenter
                : Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.dark ? p.soft : const Color(0xfffff0da),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const BrandLogo(height: 27, figma: true),
                        ),
                        const Spacer(),
                        const AppearanceButton(),
                      ],
                    ),
                    if (canGoBack)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Quay lại đăng nhập'),
                        ),
                      ),
                    const SizedBox(height: 24),
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
                    FigmaSegments(
                      labels: const ['Đăng nhập', 'Đăng ký'],
                      selected: canGoBack ? 1 : 0,
                      onChanged: (index) {
                        if (canGoBack && index == 0) {
                          Navigator.maybePop(context);
                        }
                        if (!canGoBack && index == 1) onRegister?.call();
                      },
                    ),
                    const SizedBox(height: 24),
                    if (roleSelection != null) ...[
                      roleSelection!,
                      const SizedBox(height: 20),
                    ],
                    if (api != null) ServerConnectionNotice(api: api!),
                    child,
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
          ),
        ),
      ),
    );
  }
}
