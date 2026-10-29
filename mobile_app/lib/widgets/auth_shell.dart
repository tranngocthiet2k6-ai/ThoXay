import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'design_motion.dart';
import 'appearance_button.dart';
import '../services/api_service.dart';
import 'server_connection_notice.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.canGoBack = false,
    this.api,
  });
  final String title, subtitle;
  final Widget child;
  final bool canGoBack;
  final ApiService? api;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: canGoBack
        ? AppBar(
            title: const Text('Đăng ký'),
            actions: const [AppearanceButton()],
          )
        : null,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final compact = constraints.maxWidth < 600;
          final brand = DesignSurface(
            dark: true,
            padding: EdgeInsets.all(wide ? 36 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.roofing_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'ThoXay',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    if (compact)
                      const Icon(
                        Icons.north_east_rounded,
                        color: AppColors.surface,
                        size: 22,
                      ),
                  ],
                ),
                SizedBox(height: wide ? 48 : 20),
                DesignReveal(
                  child: Text(
                    wide
                        ? 'Cùng xây\nngày mai.'
                        : 'Việc gần nhà. Thợ đúng nghề.',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: wide ? 48 : 23,
                      height: 1.15,
                      letterSpacing: wide ? -2 : -.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 20),
                  const DesignReveal(
                    child: Text(
                      'Kết nối người thợ lành nghề và chủ thầu.\nMỗi công trình, một cơ hội mới.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.7,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const ConstructionArtwork(height: 190),
                  const SizedBox(height: 28),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  const Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _TrustLabel(Icons.near_me_outlined, 'Tìm việc quanh bạn'),
                      _TrustLabel(
                        Icons.handshake_outlined,
                        'Kết nối trực tiếp',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
          final form = DesignReveal(
            child: DesignSurface(
              padding: EdgeInsets.all(compact ? 24 : 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          canGoBack
                              ? 'BẮT ĐẦU HÀNH TRÌNH'
                              : 'KHÔNG GIAN CỦA BẠN',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.of(context).muted,
                          ),
                        ),
                      ),
                      if (!canGoBack) const AppearanceButton(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontSize: wide ? 30 : 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppPalette.of(context).muted,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (api != null) ServerConnectionNotice(api: api!),
                  child,
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: AppPalette.of(context).muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Kết nối an toàn · Thông tin được bảo vệ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppPalette.of(context).muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 32,
                vertical: compact ? 20 : 40,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1060 : 520),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: brand),
                          const SizedBox(width: 24),
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
      Icon(icon, size: 17, color: AppColors.gold),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}
