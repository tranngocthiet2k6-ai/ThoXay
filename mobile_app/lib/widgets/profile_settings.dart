import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../screens/support_center_screen.dart';
import '../screens/incidents_screen.dart';
import '../theme/appearance_controller.dart';
import '../theme/app_theme.dart';
import 'app_snack_bar.dart';
import 'bouncing_button.dart';
import 'app_information.dart';

class ProfileSettings extends StatelessWidget {
  const ProfileSettings({super.key, required this.api});
  final ApiService api;

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) => BouncingButton(
    enabled: onTap != null,
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    ),
  );

  Future<void> _mode(BuildContext context, DisplayMode mode) async {
    AppHaptics.light();
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) return;
    final saved = await appearance.setMode(mode);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: const Text(
            'Đã đổi giao diện; chưa lưu được lựa chọn trên thiết bị.',
          ),
          kind: NoticeKind.info,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text('Cài đặt', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _row(
                context,
                icon: Icons.contrast,
                label: 'Giao diện Sáng / Tối',
                subtitle: appearance?.mode == DisplayMode.dark
                    ? 'Đang dùng giao diện Tối'
                    : 'Đang dùng giao diện Sáng',
                onTap: appearance == null
                    ? null
                    : () => _mode(
                        context,
                        appearance.mode == DisplayMode.dark
                            ? DisplayMode.light
                            : DisplayMode.dark,
                      ),
                trailing: Switch(
                  value: appearance?.mode == DisplayMode.dark,
                  onChanged: appearance == null
                      ? null
                      : (value) => _mode(
                          context,
                          value ? DisplayMode.dark : DisplayMode.light,
                        ),
                ),
              ),
              const Divider(height: 1, indent: 64),
              _row(
                context,
                icon: Icons.wb_sunny_outlined,
                label: 'Tương phản cao (Ngoài trời)',
                subtitle: 'Dễ đọc hơn dưới ánh nắng',
                onTap: appearance == null
                    ? null
                    : () => _mode(
                        context,
                        appearance.mode == DisplayMode.outdoor
                            ? DisplayMode.light
                            : DisplayMode.outdoor,
                      ),
                trailing: Switch(
                  value: appearance?.mode == DisplayMode.outdoor,
                  onChanged: appearance == null
                      ? null
                      : (value) => _mode(
                          context,
                          value ? DisplayMode.outdoor : DisplayMode.light,
                        ),
                ),
              ),
            ],
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _row(
                context,
                icon: Icons.support_agent,
                label: 'Trung tâm trợ giúp & SOS',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SupportCenterScreen(api: api),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 64),
              _row(
                context,
                icon: Icons.health_and_safety_outlined,
                label: 'Theo dõi sự cố & khiếu nại',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => IncidentsScreen(api: api),
                  ),
                ),
              ),
            ],
          ),
        ),
        BouncingButton(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.of(context).errorStrong,
              side: BorderSide(
                color: AppPalette.of(context).errorStrong.withValues(alpha: .3),
              ),
            ),
            onPressed: () {
              AppHaptics.light();
              api.logout();
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Đăng xuất'),
          ),
        ),
        TextButton.icon(
          onPressed: () => showDataInformation(context),
          icon: const Icon(Icons.privacy_tip_outlined, size: 18),
          label: const Text('Quyền truy cập & dữ liệu'),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: SelectableText(
            'Thợ Xây · Phiên bản ${AppRelease.label}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
