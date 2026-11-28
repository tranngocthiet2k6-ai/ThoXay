import 'bouncing_button.dart';

import 'package:flutter/material.dart';

import 'content_skeleton.dart';
import 'worker_rating_field.dart';

import '../models/models.dart';
import '../services/api_service.dart';

Future<bool?> showJobCompletionDialog(
  BuildContext context,
  ApiService api,
  Job job, {
  Map<int, int> initialRatings = const {},
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      _JobCompletionDialog(api: api, job: job, initialRatings: initialRatings),
);

class _JobCompletionDialog extends StatefulWidget {
  const _JobCompletionDialog({
    required this.api,
    required this.job,
    required this.initialRatings,
  });
  final ApiService api;
  final Job job;
  final Map<int, int> initialRatings;
  @override
  State<_JobCompletionDialog> createState() => _JobCompletionDialogState();
}

class _JobCompletionDialogState extends State<_JobCompletionDialog> {
  List<JobApplication> _workers = [];
  final Map<int, int> _ratings = {};
  bool _loading = true, _saving = false;
  String? _error;
  bool _alreadyCompleted = false;
  @override
  void initState() {
    super.initState();
    _ratings.addAll(widget.initialRatings);
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
        setState(() {
          _workers = list.where((a) => a.status == 'ACCEPTED').toList();
          _alreadyCompleted =
              widget.job.status == 'COMPLETED' ||
              _workers.any(
                (a) => a.job.status == 'COMPLETED' || a.jobRating != null,
              );
          _ratings.removeWhere(
            (id, _) => !_workers.any((a) => a.workerId == id),
          );
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    if (_saving || _alreadyCompleted) return;
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
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
              if (_alreadyCompleted)
                const Text(
                  'Công trình đã hoàn thành. Đánh giá đã chốt và không thể chấm lại.',
                ),
              for (final application in _workers)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: WorkerRatingField(
                    application: application,
                    value: _alreadyCompleted
                        ? application.jobRating
                        : _ratings[application.workerId],
                    locked: _alreadyCompleted,
                    onChanged: _saving
                        ? null
                        : (stars) => setState(
                            () => _ratings[application.workerId] = stars,
                          ),
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
        if (!_alreadyCompleted)
          BouncingButton(
            child: FilledButton(
              onPressed:
                  _loading ||
                      _saving ||
                      _workers.isEmpty ||
                      _ratings.length != _workers.length
                  ? null
                  : _complete,
              child: Text(_saving ? 'Đang lưu…' : 'Hoàn thành & lưu điểm'),
            ),
          ),
      ],
    ),
  );
}
