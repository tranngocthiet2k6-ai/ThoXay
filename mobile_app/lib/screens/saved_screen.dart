import '../widgets/design_motion.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/worker_profile.dart';
import '../services/api_service.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/job_card.dart';
import '../widgets/profile_summary.dart';
import 'shared_job_screen.dart';
import 'worker_profile_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key, required this.api, required this.worker});
  final ApiService api;
  final bool worker;
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Job> _jobs = [];
  List<WorkerProfile> _workers = [];
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
      if (widget.worker) {
        final jobs = await widget.api.savedJobs();
        if (mounted) setState(() => _jobs = jobs);
      } else {
        final workers = await widget.api.savedWorkers();
        if (mounted) setState(() => _workers = workers);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.worker ? 'Công trình yêu thích' : 'Thợ quen'),
    ),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            if (_loading) const ContentSkeleton(),
            if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
            if (!_loading &&
                _error == null &&
                _jobs.isEmpty &&
                _workers.isEmpty)
              EmptyState(
                title: widget.worker
                    ? 'Lưu cơ hội phù hợp với bạn'
                    : 'Xây dựng đội ngũ thợ tin cậy',
                message: widget.worker
                    ? 'Bấm Lưu công trình trong phần chi tiết để xem lại tại đây.'
                    : 'Bấm Lưu thợ quen trong hồ sơ để kết nối ở công trình tiếp theo.',
                action: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Khám phá ngay'),
                ),
              ),
            if (!_loading)
              for (final j in _jobs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: JobCard(
                    api: widget.api,
                    job: j,
                    action: FilledButton.tonal(
                      onPressed: () =>
                          _open(SharedJobScreen(api: widget.api, jobId: j.id)),
                      child: const Text('Mở công trình'),
                    ),
                  ),
                ),
            if (!_loading)
              for (final w in _workers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileSummary(
                        name: w.fullName,
                        worker: true,
                        rating: w.rating,
                        score: w.reputationScore,
                        completed: w.completedJobs,
                        tier: w.workerTier,
                        verified: w.verified,
                      ),
                      TextButton.icon(
                        onPressed: () => _open(
                          WorkerProfileScreen(api: widget.api, workerId: w.id),
                        ),
                        icon: const Icon(Icons.badge_outlined),
                        label: const Text('Xem hồ sơ thợ'),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}
