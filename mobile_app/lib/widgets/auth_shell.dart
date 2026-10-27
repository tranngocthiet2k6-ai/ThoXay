import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

/// A shared, keyboard-safe entry point for both account flows.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.canGoBack = false,
  });
  final String title, subtitle;
  final Widget child;
  final bool canGoBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: canGoBack
        ? AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text('Đăng ký'),
          )
        : null,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          final brand = Container(
            padding: EdgeInsets.all(wide ? 36 : 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.brandGradient(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        color: Color(0xffffdb8e),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Thợ Xây',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Việc gần nhà.\nThợ đúng nghề.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: wide ? 38 : 28,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Kết nối đôi bàn tay lành nghề với những công trình đang chờ bạn.',
                  style: TextStyle(color: Color(0xffd5eae3), height: 1.6),
                ),
                const SizedBox(height: 24),
                const Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    _TrustLabel(Icons.near_me_outlined, 'Công trình gần bạn'),
                    _TrustLabel(Icons.verified_user_outlined, 'Hồ sơ xác thực'),
                  ],
                ),
              ],
            ),
          );
          final form = Container(
            padding: EdgeInsets.all(constraints.maxWidth < 380 ? 20 : 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xffe2e8f0)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .07),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xff64748b), height: 1.5),
                ),
                const SizedBox(height: 28),
                child,
              ],
            ),
          );
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1060 : 510),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: brand),
                          const SizedBox(width: 28),
                          Expanded(child: form),
                        ],
                      )
                    : Column(
                        children: [brand, const SizedBox(height: 20), form],
                      ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _TrustLabel extends StatelessWidget {
  const _TrustLabel(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: const Color(0xffffdb8e)),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );
}
