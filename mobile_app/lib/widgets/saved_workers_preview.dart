import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/api_service.dart';
import '../services/job_links.dart';
import '../screens/worker_profile_screen.dart';
import '../theme/app_theme.dart';
import 'app_snack_bar.dart';
import 'figma_components.dart';

class SavedWorkersPreview extends StatefulWidget {
  const SavedWorkersPreview({super.key, required this.api});
  final ApiService api;
  @override
  State<SavedWorkersPreview> createState() => _SavedWorkersPreviewState();
}

class _SavedWorkersPreviewState extends State<SavedWorkersPreview> {
  List<WorkerProfile>? _workers;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final workers = await widget.api.savedWorkers();
      if (mounted) setState(() => _workers = workers);
    } catch (_) {
      if (mounted) setState(() => _workers = []);
    }
  }

  Future<void> _invite(WorkerProfile worker) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final jobs = (await widget.api.contractorJobs())
          .where((j) => j.status == 'OPEN')
          .toList();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Mời ${worker.fullName} làm việc'),
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Chọn công trình để sao chép lời mời và gửi liên kết cho thợ. Thợ vẫn tự ứng tuyển và xác nhận cam kết; thao tác này chưa gửi thông báo tự động.',
              ),
            ),
            if (jobs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Chưa có công trình đang tuyển. Hãy đăng công trình trước.',
                ),
              ),
            for (final job in jobs)
              SimpleDialogOption(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          'Mời ${worker.fullName} ứng tuyển công trình ${job.title}: ${JobLinks.share(job.id)}',
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      AppSnackBar(
                        content: const Text(
                          'Đã sao chép lời mời và liên kết công trình.',
                        ),
                      ),
                    );
                  }
                },
                child: Text(job.title),
              ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      Text('Thợ ruột đã lưu', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (_workers == null)
        const LinearProgressIndicator()
      else if (_workers!.isEmpty)
        Text(
          'Chưa lưu thợ. Mở hồ sơ ứng viên để thêm người thợ phù hợp.',
          style: TextStyle(color: AppPalette.of(context).muted),
        ),
      for (final worker in _workers ?? <WorkerProfile>[])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FigmaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        worker.fullName.characters.first.toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        worker.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (worker.verified) const KycBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '★ ${worker.rating.toStringAsFixed(1)}/5 · ${worker.completedJobs} việc hoàn thành · ${worker.reputationScore}/100 uy tín',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPalette.of(context).muted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WorkerProfileScreen(
                            api: widget.api,
                            workerId: worker.id,
                          ),
                        ),
                      ),
                      child: const Text('Xem hồ sơ'),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : () => _invite(worker),
                      child: const Text('Mời làm việc'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
