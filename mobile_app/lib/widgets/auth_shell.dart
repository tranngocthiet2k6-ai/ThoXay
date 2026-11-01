import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'appearance_button.dart';
import 'design_motion.dart';
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
  });
  final String title, subtitle;
  final Widget child;
  final bool canGoBack;
  final ApiService? api;
  final Widget? roleSelection;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: canGoBack
          ? AppBar(
              title: const Text('Đăng ký'),
              actions: const [AppearanceButton()],
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: MediaQuery.sizeOf(context).width < 600
              ? Alignment.topCenter
              : Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.engineering_outlined,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thợ Xây',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontSize: 24),
                            ),
                            Text(
                              'Kết nối tay nghề, dựng xây uy tín',
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const AppearanceButton(),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle, style: TextStyle(color: palette.muted)),
                  if (roleSelection != null) ...[
                    const SizedBox(height: 24),
                    roleSelection!,
                  ],
                  const SizedBox(height: 24),
                  DesignSurface(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          canGoBack
                              ? 'Thông tin đăng ký'
                              : 'Thông tin đăng nhập',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (api != null) ServerConnectionNotice(api: api!),
                        child,
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: palette.muted,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Thông tin được bảo vệ bằng kết nối an toàn',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: palette.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
