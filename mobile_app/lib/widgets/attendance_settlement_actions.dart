import 'bouncing_button.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../screens/job_payments_screen.dart';
import '../theme/app_theme.dart';
import 'job_completion_dialog.dart';
import 'app_snack_bar.dart';

class AttendanceSettlementActions extends StatefulWidget {
  const AttendanceSettlementActions({
    super.key,
    required this.api,
    required this.job,
    this.onReview,
    this.reviewLabel,
    this.busy = false,
  });
  final ApiService api;
  final Job job;
  final VoidCallback? onReview;
  final String? reviewLabel;
  final bool busy;
  @override
  State<AttendanceSettlementActions> createState() =>
      _AttendanceSettlementActionsState();
}

class _AttendanceSettlementActionsState
    extends State<AttendanceSettlementActions> {
  bool _completed = false, _busy = false;
  Future<void> _complete() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final done = await showJobCompletionDialog(
        context,
        widget.api,
        widget.job,
      );
      if (mounted && done == true) setState(() => _completed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completed || widget.job.status == 'COMPLETED';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        border: Border(top: BorderSide(color: AppPalette.of(context).border)),
      ),
      child: SafeArea(
        top: false,
        child: widget.onReview != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.reviewLabel ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  BouncingButton(
                    child: FilledButton.icon(
                      onPressed: widget.busy ? null : widget.onReview,
                      icon: const Icon(Icons.task_alt),
                      label: const Text(
                        'Nghiệm thu & Mở khóa thanh toán',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Xác nhận ngày công đã chọn. Thanh toán sau khi hoàn thành và đánh giá.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              )
            : Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (!completed && widget.job.status == 'IN_PROGRESS')
                    BouncingButton(
                      child: FilledButton.icon(
                        onPressed: _busy || widget.busy ? null : _complete,
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Đánh giá & hoàn thành'),
                      ),
                    ),
                  if (completed)
                    BouncingButton(
                      child: FilledButton.icon(
                        onPressed: _busy || widget.busy
                            ? null
                            : () async {
                                try {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => JobPaymentsScreen(
                                        api: widget.api,
                                        job: widget.job,
                                      ),
                                    ),
                                  );
                                } on ApiException catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      AppSnackBar(
                                        content: Text(e.message),
                                        kind: NoticeKind.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Mở thanh toán ngày công'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
