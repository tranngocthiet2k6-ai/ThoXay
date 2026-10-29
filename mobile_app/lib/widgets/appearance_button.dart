import 'package:flutter/material.dart';

import '../theme/appearance_controller.dart';
import 'app_snack_bar.dart';

class AppearanceButton extends StatelessWidget {
  const AppearanceButton({super.key});
  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) return const SizedBox.shrink();
    return PopupMenuButton<DisplayMode>(
      tooltip: 'Giao diện hiển thị',
      icon: Icon(switch (appearance.mode) {
        DisplayMode.light => Icons.light_mode_outlined,
        DisplayMode.dark => Icons.dark_mode_outlined,
        DisplayMode.outdoor => Icons.wb_sunny_outlined,
      }),
      initialValue: appearance.mode,
      onSelected: (mode) async {
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
      },
      itemBuilder: (_) => [
        for (final mode in DisplayMode.values)
          CheckedPopupMenuItem(
            value: mode,
            checked: appearance.mode == mode,
            child: Text(switch (mode) {
              DisplayMode.light => 'Sáng',
              DisplayMode.dark => 'Tối',
              DisplayMode.outdoor => 'Ngoài trời · Tương phản cao',
            }),
          ),
      ],
    );
  }
}
