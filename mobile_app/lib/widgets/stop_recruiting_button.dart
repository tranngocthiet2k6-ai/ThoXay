import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StopRecruitingButton extends StatelessWidget {
  const StopRecruitingButton({
    super.key,
    required this.onPressed,
    this.busy = false,
  });
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: palette.warning,
        foregroundColor: palette.dark && !palette.outdoor
            ? AppColors.ink
            : Colors.white,
      ),
      onPressed: busy ? null : onPressed,
      icon: const Icon(Icons.person_off_outlined),
      label: Text(busy ? 'Đang dừng tuyển…' : 'Dừng tuyển'),
    );
  }
}
