import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'figma_components.dart';
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
    final palette = AppPalette.of(context),
        color = Theme.of(context).colorScheme.primary;
    final diamond = tier == 'DIAMOND', gold = tier == 'GOLD';
    final targetScore = gold ? 95 : 80, targetJobs = gold ? 20 : 5;
    final targetStars = gold ? 4.7 : 4.0;
    final criteria = [
      math.min(score / targetScore, 1.0),
      math.min(rating / targetStars, 1.0),
      math.min(completed / targetJobs, 1.0),
      if (gold) verified ? 1.0 : 0.0,
    ];
    final progress = diamond
        ? 1.0
        : criteria.reduce((a, b) => a + b) / criteria.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FigmaCard(
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Icon(
                      worker ? Icons.person_outline : Icons.apartment_outlined,
                      color: color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          worker
                              ? 'Thợ xây · Hồ sơ nghề nghiệp'
                              : 'Chủ thầu · Quản lý công trình',
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                        if (verified)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: KycBadge(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (worker) ...[
                const Divider(height: 28),
                FigmaMetrics(
                  values: [
                    (value: '$completed', label: 'Việc hoàn thành'),
                    (
                      value: completed == 0
                          ? '—'
                          : '${rating.toStringAsFixed(1)}/5',
                      label: 'Đánh giá',
                    ),
                    (value: '$score/100', label: 'Uy tín'),
                  ],
                ),
                if (completed == 0)
                  Text(
                    'Chưa có đánh giá công trình',
                    style: TextStyle(fontSize: 11, color: palette.muted),
                  ),
              ],
            ],
          ),
        ),
        if (worker) ...[
          const SizedBox(height: 16),
          FigmaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20, color: color),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Điểm uy tín',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '$score/100',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 12),
                TierBadge(tier: tier),
                const SizedBox(height: 8),
                Text(
                  diamond
                      ? 'Bạn đã đạt bậc Kim Cương'
                      : 'Hành trình đến bậc ${gold ? "Kim Cương" : "Vàng"}',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Tiến độ đạt tiêu chí lên hạng',
                  value: '${(progress * 100).round()}%',
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                    color: palette.successStrong,
                    backgroundColor: palette.border,
                  ),
                ),
                if (!diamond)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Mục tiêu: $targetScore điểm · $targetStars sao · $targetJobs công trình${gold ? " · đã xác thực CCCD" : ""}',
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
