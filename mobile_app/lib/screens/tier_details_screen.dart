import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/tier_guide.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/design_motion.dart';
import '../widgets/empty_state.dart';
import '../widgets/modern_controls.dart';
import '../widgets/tier_badge.dart';

class TierDetailsScreen extends StatefulWidget {
  const TierDetailsScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<TierDetailsScreen> createState() => _TierDetailsScreenState();
}

class _TierDetailsScreenState extends State<TierDetailsScreen> {
  TierGuide? _guide;
  UserProfile? _profile;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.api.tierGuide(),
        widget.api.profile(),
      ]);
      if (mounted) {
        setState(() {
          _guide = results[0] as TierGuide;
          _profile = results[1] as UserProfile;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa tải được thông tin cấp bậc. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _criterion(String label, bool met) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          met ? Icons.check_circle_outline : Icons.circle_outlined,
          size: 18,
          color: met
              ? AppPalette.of(context).successStrong
              : AppPalette.of(context).muted,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final profile = _profile, guide = _guide;
    final currentIndex =
        guide?.tiers.indexWhere((rule) => rule.code == profile?.workerTier) ??
        -1;
    final current = currentIndex < 0 ? null : guide!.tiers[currentIndex];
    final next = currentIndex >= 0 && currentIndex + 1 < guide!.tiers.length
        ? guide.tiers[currentIndex + 1]
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hệ thống cấp bậc & quyền lợi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ContentFrame(
        maxWidth: 760,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              if (_loading) const ContentSkeleton(compact: true),
              if (!_loading && _error != null)
                EmptyState(
                  title: 'Chưa tải được cấp bậc',
                  message: _error!,
                  icon: Icons.workspace_premium_outlined,
                  action: OutlinedButton(
                    onPressed: _load,
                    child: const Text('Thử lại'),
                  ),
                ),
              if (!_loading &&
                  guide != null &&
                  profile != null &&
                  _error == null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          current == null
                              ? 'Tay nghề được ghi nhận bằng kết quả thực tế'
                              : 'Bậc hiện tại của bạn',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (current != null)
                          TierBadge(tier: current.code)
                        else
                          Text(
                            'Cấp bậc áp dụng cho vai trò Thợ. Bạn vẫn có thể xem các điều kiện và quyền lợi bên dưới.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (current != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            '${profile.reputationScore}/100 điểm uy tín · ${profile.completedJobs} công trình',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.completedJobs == 0
                                ? 'Chưa có đánh giá công trình'
                                : 'Đánh giá trung bình: ${profile.rating.toStringAsFixed(1)}/5',
                          ),
                          const SizedBox(height: 16),
                          GradientProgress(
                            value: next == null ? 1 : next.progress(profile),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            next == null
                                ? 'Bạn đã đạt bậc cao nhất.'
                                : 'Tiến trình lên ${next.name}: ${(next.progress(profile) * 100).round()}% · Cần đạt đủ các điều kiện.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                for (final rule in guide.tiers)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: TierBadge(tier: rule.code)),
                              if (current?.code == rule.code)
                                const Text(
                                  'Bậc hiện tại',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            rule.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _criterion(
                            '${rule.minReputation} điểm uy tín trở lên',
                            profile.reputationScore >= rule.minReputation,
                          ),
                          _criterion(
                            rule.minCompletedJobs == 0
                                ? 'Bắt đầu với tài khoản Thợ'
                                : 'Hoàn thành ít nhất ${rule.minCompletedJobs} công trình',
                            profile.completedJobs >= rule.minCompletedJobs,
                          ),
                          _criterion(
                            rule.minRating == 0
                                ? 'Chưa yêu cầu đánh giá'
                                : 'Đánh giá trung bình từ ${rule.minRating.toStringAsFixed(1)}/5',
                            rule.minRating == 0 ||
                                (profile.rating >= rule.minRating &&
                                    profile.completedJobs > 0),
                          ),
                          if (rule.requiresKyc)
                            _criterion(
                              'Định danh CCCD đã xác thực',
                              profile.verified,
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Quyền lợi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          for (final benefit in rule.benefits)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '• $benefit',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ưu tiên hiển thị & phí nền tảng',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(guide.priorityPolicy),
                        const SizedBox(height: 12),
                        Text(guide.feePolicy),
                        const SizedBox(height: 12),
                        const Text(
                          'Hủy việc bị trừ 15 điểm theo quy định hiện tại. Cấp bậc được tính lại theo điểm uy tín, đánh giá, số công trình và điều kiện KYC.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
