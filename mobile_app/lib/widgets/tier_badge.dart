import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

String tierName(String tier) => switch (tier) {
  'DIAMOND' => 'Kim Cương',
  'GOLD' => 'Vàng',
  'SILVER' => 'Bạc',
  'BRONZE' => 'Đồng',
  _ => 'Khởi đầu',
};

class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.onTap});
  final String tier;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      'DIAMOND' => AppPalette.of(context).chartBlue,
      'GOLD' => AppPalette.of(context).chartGold,
      'BRONZE' => AppPalette.of(
        context,
      ).tone(const Color(0xff9a5b21), const Color(0xfff5cba7)),
      _ => AppPalette.of(context).silverInk,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: onTap == null ? 0 : 48),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Chip(
                avatar: Icon(
                  tier == 'DIAMOND'
                      ? Icons.diamond_outlined
                      : Icons.workspace_premium_outlined,
                  color: color,
                  size: 20,
                ),
                label: Text(
                  'Bậc ${tierName(tier)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                backgroundColor: color.withValues(alpha: .06),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                side: BorderSide(color: color.withValues(alpha: .2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
