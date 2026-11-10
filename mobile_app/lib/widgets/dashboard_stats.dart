import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.values});
  final List<({String value, String label})> values;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < values.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            decoration: BoxDecoration(
              color: AppPalette.of(context).surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.of(context).border),
              boxShadow: AppPalette.of(context).outdoor
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x090F172A),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Icon(
                  [
                    Icons.campaign_outlined,
                    Icons.construction,
                    Icons.task_alt,
                  ][i % 3],
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  values[i].value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  values[i].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppPalette.of(context).muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}
