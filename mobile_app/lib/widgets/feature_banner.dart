import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

class FeatureBanner extends StatelessWidget {
  const FeatureBanner({
    super.key,
    required this.greeting,
    required this.title,
    required this.subtitle,
    this.icon = Icons.engineering_outlined,
  });
  final String greeting, title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: AppPalette.of(context).surface,
      border: Border.all(color: AppPalette.of(context).border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: AppPalette.of(context).muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: AppPalette.of(context).ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppPalette.of(context).muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width > 480) ...[
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.of(context).ink.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppPalette.of(context).ink, size: 42),
          ),
        ],
      ],
    ),
  );
}
