import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../services/api_service.dart';
import '../widgets/portfolio_gallery.dart';
import '../widgets/profile_summary.dart';
import '../widgets/worker_reviews.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({
    super.key,
    required this.api,
    required this.workerId,
  });
  final ApiService api;
  final int workerId;
  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  WorkerProfile? _person;
  String? _error;
  bool _loading = true;
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
      final person = await widget.api.workerProfile(widget.workerId);
      if (mounted) setState(() => _person = person);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hồ sơ thợ')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_error != null) ...[
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Thử lại')),
              ],
              if (_person case final person?) ...[
                ProfileSummary(
                  name: person.fullName,
                  worker: true,
                  rating: person.rating,
                  score: person.reputationScore,
                  completed: person.completedJobs,
                  tier: person.workerTier,
                  verified: person.verified,
                ),
                const SizedBox(height: 16),
                Text('${person.experienceYears} năm kinh nghiệm'),
                const SizedBox(height: 20),
                Text(
                  person.experienceSummary.isEmpty
                      ? 'Chưa bổ sung mô tả kinh nghiệm.'
                      : person.experienceSummary,
                ),
                const SizedBox(height: 20),
                Text('Kỹ năng', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (person.skills.isEmpty) const Text('Chưa bổ sung kỹ năng.'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: person.skills
                      .map((s) => Chip(label: Text(s)))
                      .toList(),
                ),
                const SizedBox(height: 24),
                PortfolioGallery(images: person.projectImages),
                const SizedBox(height: 24),
                WorkerReviews(api: widget.api, workerId: person.id),
              ],
            ],
          ),
  );
}
