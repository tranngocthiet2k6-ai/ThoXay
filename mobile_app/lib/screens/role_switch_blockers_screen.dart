import 'package:flutter/material.dart';

import '../models/role_blocker.dart';
import '../services/api_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/call_button.dart';
import '../widgets/chat_button.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/design_motion.dart';
import '../widgets/job_card.dart';
import '../widgets/job_completion_dialog.dart';
import '../widgets/stop_recruiting_button.dart';
import 'attendance_screen.dart';
import 'job_payments_screen.dart';

class RoleSwitchBlockersScreen extends StatefulWidget {
  const RoleSwitchBlockersScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<RoleSwitchBlockersScreen> createState() =>
      _RoleSwitchBlockersScreenState();
}

class _RoleSwitchBlockersScreenState extends State<RoleSwitchBlockersScreen> {
  List<RoleBlocker> _items = [];
  bool _loading = true, _busy = false;
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
      final items = await widget.api.roleBlockers();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _load();
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

  Future<void> _stop(RoleBlocker item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dừng tuyển thợ?'),
        content: const Text(
          'Giữ nguyên thợ đã duyệt, từ chối mọi đơn chờ và ngừng nhận đơn mới. Không thể mở tuyển lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận dừng tuyển'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _run(() async {
        await widget.api.stopRecruiting(item.job.id);
      });
    }
  }

  Widget _card(RoleBlocker item) {
    final job = item.job;
    final message = item.unpaid
        ? item.owner
              ? 'Công trình còn chờ thanh toán. Hãy thanh toán đủ tiền công cho các thợ chưa nhận tiền.'
              : 'Chủ thầu chưa chốt thanh toán tiền công của bạn. Liên hệ chủ thầu để đối soát và nhận tiền vào ví.'
        : item.owner
        ? 'Hãy dừng tuyển nếu không cần thêm thợ. Khi còn thợ đã nhận, cần hoàn thành công trình và thanh toán trước khi chuyển vai trò.'
        : 'Đơn ứng tuyển hoặc công việc này chưa kết thúc. Mở công trình để xem trạng thái và liên hệ chủ thầu khi đơn đã được duyệt.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            JobStatusBadge(status: job.displayStatus),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => showJobDetails<void>(
                    context,
                    job,
                    api: widget.api,
                    canContactContractor:
                        !item.owner && job.contractorPhone != null,
                  ),
                  child: const Text('Xem công trình'),
                ),
                if (item.owner && item.unpaid)
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => JobPaymentsScreen(
                                  api: widget.api,
                                  job: job,
                                ),
                              ),
                            );
                          }),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Thanh toán tiền công'),
                  ),
                if (item.owner && !item.unpaid) ...[
                  if (job.canRecruit)
                    StopRecruitingButton(
                      onPressed: _busy ? null : () => _stop(item),
                    ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    AttendanceScreen(api: widget.api, job: job),
                              ),
                            );
                          }),
                    child: const Text('Chấm công & nghiệm thu'),
                  ),
                  if (job.status == 'IN_PROGRESS' && !job.ratingsFinalized)
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await showJobCompletionDialog(
                                context,
                                widget.api,
                                job,
                              );
                            }),
                      child: const Text('Chốt đánh giá'),
                    ),
                ],
                if (!item.owner && job.contractorPhone != null) ...[
                  CallButton(
                    phone: job.contractorPhone!,
                    label: 'Gọi chủ thầu',
                  ),
                  ChatButton(
                    api: widget.api,
                    job: job,
                    peerId: job.contractorId,
                    peerName: job.contractorName,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Công việc cần xử lý')),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: _busy ? () async {} : _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text(
              'Hoàn tất các công việc dưới đây, sau đó quay lại Cài đặt để chuyển vai trò.',
            ),
            const SizedBox(height: 16),
            if (_loading) const ContentSkeleton(),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!),
              OutlinedButton(
                onPressed: _loading ? null : _load,
                child: const Text('Thử lại'),
              ),
            ],
            if (!_loading && _error == null && _items.isEmpty) ...[
              const Text(
                'Đã xử lý xong. Bạn có thể quay lại để chuyển vai trò.',
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại chuyển vai trò'),
              ),
            ],
            if (!_loading && _error == null) ..._items.map(_card),
          ],
        ),
      ),
    ),
  );
}
