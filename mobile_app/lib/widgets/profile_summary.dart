import 'modern_controls.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'figma_components.dart';
import 'tier_badge.dart';
import 'commercial_hero.dart';

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
    this.phone,
    this.avatar,
    this.onAvatarTap,
    this.onTierTap,
  });
  final String name, tier;
  final String? phone;
  final Widget? avatar;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onTierTap;
  final bool worker, verified;
  final double rating;
  final int score, completed;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context),
        color = Theme.of(context).colorScheme.primary;
    final diamond = tier == 'DIAMOND',
        gold = tier == 'GOLD',
        bronze = tier == 'BRONZE';
    final targetScore = bronze
            ? 60
            : gold
            ? 95
            : 80,
        targetJobs = bronze
            ? 1
            : gold
            ? 20
            : 5;
    final targetStars = bronze
        ? 3.0
        : gold
        ? 4.7
        : 4.0;
    final criteria = [
      math.min(score / targetScore, 1.0),
      completed == 0 ? 0.0 : math.min(rating / targetStars, 1.0),
      math.min(completed / targetJobs, 1.0),
      if (gold) verified ? 1.0 : 0.0,
    ];
    final progress = diamond
        ? 1.0
        : criteria.reduce((a, b) => a + b) / criteria.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommercialHero(
          child: Column(
            children: [
              Row(
                children: [
                  Semantics(
                    button: onAvatarTap != null,
                    label: onAvatarTap == null ? null : 'Đổi ảnh đại diện',
                    child: InkWell(
                      onTap: onAvatarTap,
                      borderRadius: BorderRadius.circular(40),
                      child: SizedBox.square(
                        dimension: 72,
                        child: Stack(
                          children: [
                            Center(
                              child:
                                  avatar ??
                                  PresenceAvatar(name: name, size: 64),
                            ),
                            if (onAvatarTap != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 16,
                                    color: Color(0xff0f172a),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          worker
                              ? 'Thợ xây · Hồ sơ nghề nghiệp'
                              : 'Chủ thầu · Quản lý công trình',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xffcbd5e1),
                          ),
                        ),
                        if (phone != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              phone!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
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
                  inverse: true,
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xffcbd5e1),
                    ),
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
                GradientProgress(value: (score / 100).clamp(0.0, 1.0)),
                const SizedBox(height: 12),
                TierBadge(tier: tier, onTap: onTierTap),
                const SizedBox(height: 8),
                Text(
                  diamond
                      ? 'Bạn đã đạt bậc Kim Cương'
                      : 'Hành trình đến bậc ${bronze
                            ? "Bạc"
                            : gold
                            ? "Kim Cương"
                            : "Vàng"}',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Tiến độ đạt tiêu chí lên hạng',
                  value: '${(progress * 100).round()}%',
                  child: GradientProgress(
                    value: progress,
                    color: palette.successStrong,
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
