import 'modern_controls.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'figma_components.dart';
import 'tier_badge.dart';
import 'commercial_hero.dart';
import 'figma_design.dart';

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
    this.figma = false,
    this.profession,
  });
  final String name, tier;
  final String? phone;
  final bool figma;
  final String? profession;
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
    if (figma) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Semantics(
                button: onAvatarTap != null,
                label: 'Đổi ảnh đại diện',
                child: InkWell(
                  key: const ValueKey('profile-avatar-change'),
                  onTap: onAvatarTap,
                  borderRadius: BorderRadius.circular(40),
                  child: SizedBox.square(
                    dimension: 76,
                    child: Stack(
                      children: [
                        Center(
                          child: avatar ?? PresenceAvatar(name: name, size: 70),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.border),
                            ),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 15,
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profession ?? (worker ? 'Thợ xây' : 'Chủ thầu'),
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                    if (phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone!,
                        style: TextStyle(fontSize: 11, color: palette.muted),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        FigmaIcon(
                          '4cf24',
                          size: 13,
                          color: verified
                              ? palette.successStrong
                              : palette.muted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            verified
                                ? 'Đã xác minh danh tính'
                                : 'Chưa xác minh danh tính',
                            style: TextStyle(
                              fontSize: 10,
                              color: verified
                                  ? palette.successStrong
                                  : palette.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final item in [
                (value: '$completed', label: 'Việc hoàn thành'),
                (
                  value: completed == 0 ? '—' : rating.toStringAsFixed(1),
                  label: 'Đánh giá',
                ),
                (value: '—', label: 'Đúng giờ'),
              ])
                Expanded(
                  child: Tooltip(
                    message: item.label == 'Đúng giờ'
                        ? 'Chưa có thống kê tỷ lệ đúng giờ từ hệ thống chấm công.'
                        : item.label,
                    child: Column(
                      children: [
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.label,
                          style: TextStyle(fontSize: 10, color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (worker && completed == 0) ...[
            const SizedBox(height: 10),
            Text(
              'Chưa có đánh giá công trình',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: palette.muted),
            ),
          ],
          const SizedBox(height: 22),
          FigmaCard(
            child: InkWell(
              onTap: onTierTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      FigmaIcon('65dcf', size: 22, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: worker
                            ? TierBadge(tier: tier, onTap: onTierTap)
                            : const Text(
                                'Hệ thống cấp bậc thợ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const FigmaIcon('af1cb', size: 17),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final label in ['Đồng', 'Bạc', 'Vàng', 'Kim Cương'])
                        Text(
                          label,
                          style: TextStyle(fontSize: 10, color: palette.muted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (worker)
                    Semantics(
                      label: 'Tiến độ đạt tiêu chí lên hạng',
                      value: '${(progress * 100).round()}%',
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    !worker
                        ? 'Tìm hiểu tiêu chí và huy hiệu uy tín của đội thợ.'
                        : diamond
                        ? 'Bạn đã đạt bậc Kim Cương'
                        : 'Hành trình đến bậc ${bronze
                              ? 'Bạc'
                              : gold
                              ? 'Kim Cương'
                              : 'Vàng'}',
                    style: TextStyle(fontSize: 11, color: palette.muted),
                  ),
                  if (worker) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Uy tín: $score/100${diamond ? '' : ' · Mục tiêu: $targetScore điểm · $targetStars sao · $targetJobs công trình${gold ? ' · đã KYC' : ''}'}',
                      style: TextStyle(fontSize: 10, color: palette.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }
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
