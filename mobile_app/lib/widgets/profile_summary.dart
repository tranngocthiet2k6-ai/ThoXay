import 'design_motion.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tier_badge.dart';

class ProfileSummary extends StatelessWidget {
  const ProfileSummary({
    super.key,
    required this.name,
    required this.worker,
    required this.rating,
    required this.score,
    required this.completed,
    required this.tier,
    required this.verified,
  });
  final String name, tier;
  final bool worker, verified;
  final double rating;
  final int score, completed;
  @override
  Widget build(BuildContext context) {
    final diamond = tier == 'DIAMOND';
    final gold = tier == 'GOLD';
    final targetScore = gold ? 95 : 80, targetJobs = gold ? 20 : 5;
    final targetStars = gold ? 4.7 : 4.0;
    // Display progress only; the server's tier remains authoritative.
    final criteria = [
      math.min(score / targetScore, 1.0),
      math.min(rating / targetStars, 1.0),
      math.min(completed / targetJobs, 1.0),
      if (gold) verified ? 1.0 : 0.0,
    ];
    final progress = diamond
        ? 1.0
        : criteria.reduce((a, b) => a + b) / criteria.length;
    return DesignReveal(
      child: DesignSurface(
        dark: true,
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            color: Colors.white,
            height: 1.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (verified)
                    const Tooltip(
                      message: 'Đã xác thực CCCD',
                      child: Icon(Icons.verified, color: AppColors.skySoft),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (worker) ...[
                TierBadge(tier: tier),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      completed == 0
                          ? 'Chưa có đánh giá'
                          : '★ ${rating.toStringAsFixed(1)}/5 sao',
                    ),
                    Text('$score/100 uy tín'),
                    Text('$completed công trình'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  diamond
                      ? 'Bạn đã đạt bậc Kim Cương'
                      : 'Hành trình đến bậc ${gold ? 'Kim Cương' : 'Vàng'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Tiến độ đạt tiêu chí lên hạng',
                  value: '${(progress * 100).round()}%',
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 8),
                if (!diamond)
                  Text(
                    'Mục tiêu: $targetScore điểm · $targetStars sao · $targetJobs công trình${gold ? ' · đã xác thực CCCD' : ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
              ] else
                const Text(
                  'Chủ thầu · Kết nối nhân lực cho công trình của bạn',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
