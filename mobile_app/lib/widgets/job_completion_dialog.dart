import 'package:flutter/material.dart';

import 'content_skeleton.dart';

import '../models/models.dart';
import '../services/api_service.dart';

Future<bool?> showJobCompletionDialog(
  BuildContext context,
  ApiService api,
  Job job,
) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _JobCompletionDialog(api: api, job: job),
);

class _JobCompletionDialog extends StatefulWidget {
  const _JobCompletionDialog({required this.api, required this.job});
  final ApiService api;
  final Job job;
  @override
  State<_JobCompletionDialog> createState() => _JobCompletionDialogState();
}

class _JobCompletionDialogState extends State<_JobCompletionDialog> {
  List<JobApplication> _workers = [];
  final Map<int, int> _ratings = {};
  bool _loading = true, _saving = false;
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
      final list = await widget.api.jobApplications(widget.job.id);
      if (mounted) {
        setState(
          () => _workers = list.where((a) => a.status == 'ACCEPTED').toList(),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.completeJob(widget.job.id, _ratings);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Hoàn thành & đánh giá thợ'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.job.title),
              const SizedBox(height: 12),
              const Text(
                'Chọn từ 1 đến 5 sao cho từng thợ đã tham gia. Đánh giá sẽ được lưu khi xác nhận hoàn thành.',
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: ContentSkeleton(compact: true),
                ),
              for (final application in _workers)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.workerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Wrap(
                        children: [
                          for (int stars = 1; stars <= 5; stars++)
                            IconButton(
                              tooltip:
                                  'Chấm $stars sao cho ${application.workerName}',
                              visualDensity: VisualDensity.compact,
                              onPressed: _saving
                                  ? null
                                  : () => setState(
                                      () => _ratings[application.workerId] =
                                          stars,
                                    ),
                              icon: Icon(
                                (_ratings[application.workerId] ?? 0) >= stars
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber.shade800,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _ratings.containsKey(application.workerId)
                            ? '${_ratings[application.workerId]} / 5 sao'
                            : 'Chưa chọn điểm',
                      ),
                    ],
                  ),
                ),
              if (!_loading && _workers.isEmpty && _error == null)
                const Text('Không có thợ đã được nhận để đánh giá.'),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (_workers.isEmpty)
                  TextButton(onPressed: _load, child: const Text('Tải lại')),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed:
              _loading ||
                  _saving ||
                  _workers.isEmpty ||
                  _ratings.length != _workers.length
              ? null
              : _complete,
          child: Text(_saving ? 'Đang lưu…' : 'Hoàn thành & lưu điểm'),
        ),
      ],
    ),
  );
}
