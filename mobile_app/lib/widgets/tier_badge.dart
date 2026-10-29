import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

String tierName(String tier) => switch (tier) {
  'DIAMOND' => 'Kim Cương',
  'GOLD' => 'Vàng',
  _ => 'Bạc',
};

class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier});
  final String tier;
  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      'DIAMOND' => AppPalette.of(context).chartBlue,
      'GOLD' => AppPalette.of(context).chartGold,
      _ => AppPalette.of(context).silverInk,
    };
    return Chip(
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
      backgroundColor: color.withValues(alpha: .08),
      side: BorderSide(color: color.withValues(alpha: .2)),
    );
  }
}
