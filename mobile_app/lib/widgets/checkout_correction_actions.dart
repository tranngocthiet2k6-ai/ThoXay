import 'package:flutter/material.dart';

import '../models/attendance.dart';
import '../models/models.dart';
import '../models/scheduling.dart';
import '../services/api_service.dart';

String correctionStatusLabel(String? status) => switch (status) {
  'PENDING' => 'Chờ duyệt điều chỉnh chấm công',
  'AUTO_UNDONE' => 'Đã hoàn tác kết thúc ca',
  'APPROVED' => 'Đã duyệt điều chỉnh chấm công',
  'REJECTED' => 'Đã từ chối điều chỉnh chấm công',
  _ => '',
};

class CheckoutCorrectionActions extends StatefulWidget {
  const CheckoutCorrectionActions({
    super.key,
    required this.api,
    required this.row,
    required this.job,
    required this.worker,
    required this.today,
    required this.onChanged,
    this.enabled = true,
  });
  final ApiService api;
  final AttendanceEntry row;
  final Job job;
  final bool worker, enabled;
  final DateTime today;
  final Future<void> Function() onChanged;
  @override
  State<CheckoutCorrectionActions> createState() =>
      _CheckoutCorrectionActionsState();
}

class _CheckoutCorrectionActionsState extends State<CheckoutCorrectionActions> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<String> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CorrectionDialog(canUndo: widget.row.canUndoCheckout),
    );
    if (reason == null || !mounted) return;
    await _run(() async {
      final status = await widget.api.correctCheckout(widget.row, reason);
      return status == 'AUTO_UNDONE'
          ? 'Đã mở lại ca, giữ nguyên giờ vào. Bạn có thể tiếp tục làm.'
          : 'Đã gửi yêu cầu. Chủ thầu cần duyệt trước khi sửa chấm công.';
    });
  }

  Future<void> _review(bool approved) async {
    final row = widget.row;
    final reopen =
        isoDay(row.day) == isoDay(widget.today) &&
        (widget.job.status == 'OPEN' || widget.job.status == 'IN_PROGRESS');
    final result = await showDialog<_CorrectionDecision>(
      context: context,
      builder: (_) => _CorrectionReviewDialog(
        row: row,
        approved: approved,
        canReopen: reopen,
      ),
    );
    if (result == null || !mounted) return;
    await _run(() async {
      await widget.api.reviewCheckoutCorrection(
        row,
        approved,
        correctedCheckedOutAt: result.end,
        feedback: result.feedback,
      );
      return approved
          ? 'Đã duyệt điều chỉnh. Cần nghiệm thu lại ảnh công việc.'
          : 'Đã từ chối yêu cầu điều chỉnh.';
    });
  }

  Future<void> _history() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lịch sử điều chỉnh chấm công'),
        content: SizedBox(
          width: 440,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.api.checkoutCorrections(widget.row.id),
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Không tải được lịch sử. Hãy đóng và thử lại.',
                );
              }
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 70,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in snapshot.data!) ...[
                      Text(
                        correctionStatusLabel(item['status'] as String?),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Giờ ra ban đầu: ${_timestamp(item['originalCheckedOutAt'])} · ${item['originalMethod']}',
                      ),
                      Text(
                        'Yêu cầu: ${_timestamp(item['requestedAt'])} · Tài khoản #${item['requestedBy']}',
                      ),
                      Text('Lý do: ${item['reason']}'),
                      if (item['reviewedAt'] != null)
                        Text(
                          'Xử lý: ${_timestamp(item['reviewedAt'])} · Tài khoản #${item['reviewedBy']}',
                        ),
                      if (item['status'] == 'APPROVED')
                        Text(
                          item['correctedCheckedOutAt'] == null
                              ? 'Kết quả: Mở lại ca'
                              : 'Giờ ra đã sửa: ${_timestamp(item['correctedCheckedOutAt'])}',
                        ),
                      if ((item['feedback'] as String? ?? '').isNotEmpty)
                        Text('Phản hồi: ${item['feedback']}'),
                      const Divider(),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _timestamp(dynamic raw) {
    final vn = DateTime.parse(raw as String)
        .toUtc()
        .add(const Duration(hours: 7));
    return '${isoDay(vn)} ${vn.hour.toString().padLeft(2, '0')}:${vn.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final enabled = widget.enabled && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_busy) const LinearProgressIndicator(),
        if (row.correctionStatus != null) ...[
          Text(
            correctionStatusLabel(row.correctionStatus),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text('Lý do: ${row.correctionReason}'),
          if (row.correctionFeedback.isNotEmpty)
            Text('Phản hồi: ${row.correctionFeedback}'),
        ],
        if (widget.worker && row.checkedOutAt != null && !row.correctionPending)
          TextButton.icon(
            onPressed: enabled ? _request : null,
            icon: const Icon(Icons.undo),
            label: const Text('Báo kết thúc nhầm'),
          ),
        if (!widget.worker && row.correctionPending)
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: enabled ? () => _review(true) : null,
                child: const Text('Duyệt điều chỉnh'),
              ),
              OutlinedButton(
                onPressed: enabled ? () => _review(false) : null,
                child: const Text('Từ chối điều chỉnh'),
              ),
            ],
          ),
        if (row.correctionId != null)
          TextButton(
            onPressed: enabled ? _history : null,
            child: const Text('Xem lịch sử điều chỉnh'),
          ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class _CorrectionDialog extends StatefulWidget {
  const _CorrectionDialog({required this.canUndo});
  final bool canUndo;
  @override
  State<_CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends State<_CorrectionDialog> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Báo kết thúc nhầm'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.canUndo
                ? 'Trong 2 phút và chưa nghiệm thu, ca được mở lại, giữ nguyên giờ vào. Nếu quá hạn khi gửi, yêu cầu sẽ chuyển chủ thầu duyệt.'
                : 'Chủ thầu sẽ xem lý do và duyệt mở lại ca hoặc sửa giờ ra. Giờ ra hiện tại được giữ trong lúc chờ duyệt.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reason,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Lý do điều chỉnh'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nhập lý do điều chỉnh'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _reason.text.trim());
          }
        },
        child: Text(
          widget.canUndo ? 'Hoàn tác kết thúc ca' : 'Gửi yêu cầu điều chỉnh',
        ),
      ),
    ],
  );
}

class _CorrectionDecision {
  const _CorrectionDecision(this.end, this.feedback);
  final DateTime? end;
  final String feedback;
}

class _CorrectionReviewDialog extends StatefulWidget {
  const _CorrectionReviewDialog({
    required this.row,
    required this.approved,
    required this.canReopen,
  });
  final AttendanceEntry row;
  final bool approved, canReopen;
  @override
  State<_CorrectionReviewDialog> createState() =>
      _CorrectionReviewDialogState();
}

class _CorrectionReviewDialogState extends State<_CorrectionReviewDialog> {
  final _feedback = TextEditingController();
  final _form = GlobalKey<FormState>();
  late bool _reopen = widget.canReopen;
  TimeOfDay? _time;
  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.approved ? 'Duyệt điều chỉnh chấm công' : 'Từ chối điều chỉnh',
    ),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.row.workerName}\nLý do: ${widget.row.correctionReason}',
            ),
            if (widget.approved) ...[
              if (widget.canReopen)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mở lại ca để tiếp tục làm'),
                  value: _reopen,
                  onChanged: (value) => setState(() => _reopen = value),
                ),
              if (!_reopen)
                OutlinedButton(
                  onPressed: () async {
                    final vn = widget.row.checkedOutAt!.toUtc().add(
                      const Duration(hours: 7),
                    );
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(vn),
                    );
                    if (time != null && mounted) setState(() => _time = time);
                  },
                  child: Text(
                    _time == null
                        ? 'Chọn giờ ra đúng (giờ Việt Nam)'
                        : 'Giờ ra: ${_time!.format(context)} · ${isoDay(widget.row.day)}',
                  ),
                ),
              const Text(
                'Duyệt sửa chấm công sẽ yêu cầu nghiệm thu lại ảnh công việc.',
              ),
            ],
            TextFormField(
              controller: _feedback,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: widget.approved
                    ? 'Phản hồi (không bắt buộc)'
                    : 'Lý do từ chối',
              ),
              validator: (value) =>
                  !widget.approved && (value?.trim().isEmpty ?? true)
                  ? 'Nhập lý do từ chối'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        onPressed: widget.approved && !_reopen && _time == null
            ? null
            : () {
                if (!_form.currentState!.validate()) return;
                final day = widget.row.day;
                final end = widget.approved && !_reopen
                    ? DateTime.utc(
                        day.year,
                        day.month,
                        day.day,
                        _time!.hour,
                        _time!.minute,
                      ).subtract(const Duration(hours: 7))
                    : null;
                Navigator.pop(
                  context,
                  _CorrectionDecision(end, _feedback.text.trim()),
                );
              },
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
