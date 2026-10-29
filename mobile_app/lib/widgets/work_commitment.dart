import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/scheduling.dart';
import '../services/api_service.dart';

class HiringDecision {
  const HiringDecision(this.version, this.acceptOffer);
  final int version;
  final bool acceptOffer;
}

Future<WorkProposal?> showWorkProposal(
  BuildContext context,
  ApiService api,
  Job job,
) => showDialog<WorkProposal>(
  context: context,
  builder: (_) => WorkCommitmentDialog(api: api, job: job),
);
Future<WorkProposal?> showWorkerCommitment(
  BuildContext context,
  ApiService api,
  JobApplication application,
) => showDialog<WorkProposal>(
  context: context,
  builder: (_) => WorkCommitmentDialog(api: api, application: application),
);
Future<HiringDecision?> showHiringCommitment(
  BuildContext context,
  ApiService api,
  JobApplication application,
) => showDialog<HiringDecision>(
  context: context,
  builder: (_) => WorkCommitmentDialog(
    api: api,
    application: application,
    contractor: true,
  ),
);

class WorkCommitmentDialog extends StatefulWidget {
  const WorkCommitmentDialog({
    super.key,
    required this.api,
    this.job,
    this.application,
    this.contractor = false,
  });
  final ApiService api;
  final Job? job;
  final JobApplication? application;
  final bool contractor;
  @override
  State<WorkCommitmentDialog> createState() => _WorkCommitmentDialogState();
}

class _WorkCommitmentDialogState extends State<WorkCommitmentDialog> {
  final _rate = TextEditingController(), _note = TextEditingController();
  CommitmentDocument? _document;
  bool _busy = false, _accepted = false, _dirty = false, _offer = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rate.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _proposed =>
      _rate.text.trim().isEmpty ? null : int.tryParse(_rate.text.trim());
  Future<void> _load() async {
    if (_busy) return;
    if (widget.job != null &&
        _rate.text.trim().isNotEmpty &&
        (_proposed == null || _proposed! < 1 || _proposed! > 1000000000)) {
      setState(() => _error = 'Lương đề xuất từ 1 đến 1.000.000.000đ');
      return;
    }
    setState(() {
      _busy = true;
      _accepted = false;
      _document = null;
      _error = null;
    });
    try {
      final document = widget.job != null
          ? await widget.api.jobTerms(widget.job!.id, proposedRate: _proposed)
          : await widget.api.commitment(
              widget.application!.id,
              acceptOffer: _offer,
            );
      if (mounted) {
        setState(() {
          _document = document;
          _dirty = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (_document == null || !_accepted || _busy || _dirty) return;
    Navigator.pop(
      context,
      widget.contractor
          ? HiringDecision(_document!.version, _offer)
          : WorkProposal(
              version: _document!.version,
              rate: _proposed,
              note: _note.text.trim(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Cam kết nhận việc'),
    content: SizedBox(
      width: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.job != null) ...[
            TextField(
              key: const ValueKey('proposal-rate'),
              controller: _rate,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lương mong muốn/ngày (không bắt buộc)',
                suffixText: 'đ',
              ),
              onChanged: (_) => setState(() {
                _dirty = true;
                _accepted = false;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú thương lượng',
              ),
            ),
            if (_dirty)
              OutlinedButton(
                onPressed: _busy ? null : _load,
                child: const Text('Cập nhật cam kết'),
              ),
            const SizedBox(height: 12),
          ],
          if (widget.contractor &&
              widget.application?.proposedDailyRate != null) ...[
            Text(
              'Đề xuất: ${money(widget.application!.proposedDailyRate!.toDouble())}/ngày',
            ),
            if (widget.application?.wageNote?.isNotEmpty ?? false)
              Text(widget.application!.wageNote!),
            RadioGroup<bool>(
              groupValue: _offer,
              onChanged: (value) {
                if (_busy || value == null) return;
                setState(() => _offer = value);
                _load();
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: false,
                    enabled: !_busy,
                    title: const Text('Giữ giá gốc'),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    enabled: !_busy,
                    title: const Text('Chấp nhận mức đề xuất'),
                  ),
                ],
              ),
            ),
          ],
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
          if (_document != null) ...[
            SizedBox(
              height: 240,
              child: SingleChildScrollView(
                child: SelectableText(_document!.text),
              ),
            ),
            const SizedBox(height: 12),
            if (_document!.hash != null)
              Text(
                'SHA-256: ${_document!.hash}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            CheckboxListTile(
              key: const ValueKey('commitment-consent'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Tôi đã đọc và đồng ý các điều khoản trên'),
              value: _accepted,
              onChanged: _busy || _dirty
                  ? null
                  : (v) => setState(() => _accepted = v ?? false),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Để sau'),
      ),
      FilledButton(
        onPressed: _accepted && !_busy && !_dirty && _document != null
            ? _submit
            : null,
        child: Text(
          widget.contractor
              ? 'Xác nhận nhận thợ'
              : widget.job != null
              ? 'Đồng ý & ứng tuyển'
              : 'Xác nhận cam kết',
        ),
      ),
    ],
  );
}
