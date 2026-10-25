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
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xff103f34), Color(0xff218365)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff176b52).withValues(alpha: .13),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(color: Color(0xffc6e6d9), fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xffd7ede4),
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: const Color(0xffe0efe5), size: 42),
          ),
        ],
      ],
    ),
  );
}
