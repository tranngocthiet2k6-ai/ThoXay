import '../widgets/design_motion.dart';
import '../widgets/content_skeleton.dart';

import 'package:flutter/material.dart';

import '../models/reputation.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/tier_badge.dart';
import '../widgets/ranking_podium.dart';
import 'worker_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<WorkerRank> _rows = [];
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
      final rows = await widget.api.leaderboard();
      if (mounted) setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bảng xếp hạng thợ')),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SectionIntro(
              title: 'Uy tín được xây từ công việc thật',
              subtitle: 'Vinh danh những người thợ được tin tưởng.',
              eyebrow: 'BẢNG XẾP HẠNG',
            ),
            const SizedBox(height: 12),
            const Text(
              'Chỉ xếp hạng thợ đang hoạt động và đã có đánh giá công trình. Ưu tiên bậc thợ, điểm uy tín, sao và số công trình hoàn thành.',
            ),
            const SizedBox(height: 12),
            const Card(
              child: ExpansionTile(
                title: Text('Cách tính bậc thợ'),
                childrenPadding: EdgeInsets.all(16),
                children: [
                  Text(
                    'Bạc: bậc khởi đầu.\n\nVàng: từ 80 điểm, 4.0 sao và 5 công trình hoàn thành.\n\nKim Cương: từ 95 điểm, 4.7 sao, 20 công trình và đã xác thực CCCD.\n\nUy tín tối đa 100. Hoàn thành công trình cộng 2 điểm; hủy việc đang làm trừ 15 điểm và tính lại bậc.',
                  ),
                ],
              ),
            ),
            if (_loading && _rows.isEmpty) const ContentSkeleton(compact: true),
            if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
            if (!_loading && _error == null && _rows.isEmpty)
              EmptyState(
                icon: Icons.emoji_events_outlined,
                action: OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra lại'),
                ),
                title: 'Chưa có dữ liệu xếp hạng',
                message: 'Hoàn thành công trình và nhận đánh giá để bắt đầu hành trình uy tín.',
              ),
            if (!_loading && _error == null && _rows.isNotEmpty)
              RankingPodium(
                workers: _rows.take(3).toList(),
                onTap: (worker) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkerProfileScreen(
                      api: widget.api,
                      workerId: worker.workerId,
                    ),
                  ),
                ),
              ),
            for (final worker in _rows.skip(3))
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WorkerProfileScreen(
                        api: widget.api,
                        workerId: worker.workerId,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(child: Text('${worker.rank}')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                worker.fullName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TierBadge(tier: worker.workerTier),
                            Text('${worker.reputationScore}/100 uy tín'),
                            Text('★ ${worker.rating.toStringAsFixed(1)}/5'),
                          ],
                        ),
                        Text(
                          '${worker.completedJobs} công trình hoàn thành${worker.verified ? ' · Đã xác thực CCCD' : ''}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
