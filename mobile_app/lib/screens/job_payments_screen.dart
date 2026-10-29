import '../widgets/design_motion.dart';
import '../widgets/app_snack_bar.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import 'wallet_screen.dart';
import '../widgets/content_skeleton.dart';

class JobPaymentsScreen extends StatefulWidget {
  const JobPaymentsScreen({super.key, required this.api, required this.job});
  final ApiService api;
  final Job job;
  @override
  State<JobPaymentsScreen> createState() => _JobPaymentsScreenState();
}

class _JobPaymentsScreenState extends State<JobPaymentsScreen> {
  List<JobApplication> _workers = [];
  List<JobPayment> _payments = [];
  WalletBalance? _wallet;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final people = await widget.api.jobApplications(widget.job.id);
      final payments = await widget.api.jobPayments(widget.job.id);
      final balance = await widget.api.wallet();
      if (mounted) {
        setState(() {
          _workers = people.where((a) => a.status == 'ACCEPTED').toList();
          _payments = payments;
          _wallet = balance;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay(JobApplication worker) async {
    if (_busy || _wallet == null) return;
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => _PayDialog(
        api: widget.api,
        job: widget.job,
        application: worker,
        available: _wallet!.main,
      ),
    );
    if (mounted) {
      if (done == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text('Đã thanh toán thu nhập vào ví của thợ.')),
        );
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thanh toán thu nhập')),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SectionIntro(
              title: 'Chi trả công trình',
              subtitle:
                  'Kiểm tra ngày công và xác nhận thanh toán cho từng thợ.',
              eyebrow: 'TÀI CHÍNH',
            ),
            Text(
              widget.job.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nhập số ngày công đã xác nhận với từng thợ. Tiền công, tip và thưởng được chuyển từ số dư khả dụng của bạn; mỗi thợ chỉ được thanh toán một lần cho công trình.',
            ),
            if (_wallet != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Khả dụng: ${money(_wallet!.main.toDouble())}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            TextButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WalletScreen(api: widget.api),
                  ),
                );
                if (mounted) await _load();
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Mở ví / nạp tiền'),
            ),
            if (_busy && _wallet == null) const ContentSkeleton(compact: true),
            if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
            for (final worker in _workers)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        worker.workerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_payments
                              .where((p) => p.applicationId == worker.id)
                              .firstOrNull
                          case final payment?) ...[
                        const Chip(label: Text('Đã thanh toán')),
                        Text(
                          '${payment.days} ngày công · ${money(payment.total.toDouble())}',
                        ),
                        Text(
                          'Tip ${money(payment.tip.toDouble())} · Thưởng ${money(payment.bonus.toDouble())}',
                        ),
                      ] else
                        FilledButton.icon(
                          onPressed: _busy ? null : () => _pay(worker),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text('Thanh toán cho ${worker.workerName}'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _PayDialog extends StatefulWidget {
  const _PayDialog({
    required this.api,
    required this.job,
    required this.application,
    required this.available,
  });
  final ApiService api;
  final Job job;
  final JobApplication application;
  final int available;
  @override
  State<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends State<_PayDialog> {
  final _form = GlobalKey<FormState>();
  final _days = TextEditingController(),
      _tip = TextEditingController(text: '0'),
      _bonus = TextEditingController(text: '0');
  bool _confirmed = false, _busy = false;
  String? _error;
  int get _total =>
      (widget.application.agreedDailyRate ?? widget.job.salaryPerDay.round()) *
          (int.tryParse(_days.text) ?? 0) +
      (int.tryParse(_tip.text) ?? 0) +
      (int.tryParse(_bonus.text) ?? 0);
  @override
  void dispose() {
    _days.dispose();
    _tip.dispose();
    _bonus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.payWorker({
        'applicationId': widget.application.id,
        'workDays': int.parse(_days.text),
        'tip': int.parse(_tip.text),
        'bonus': int.parse(_bonus.text),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _number(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        return n == null || !RegExp(r'^\d+$').hasMatch(v!) || n < min || n > max
            ? 'Nhập số nguyên từ $min đến $max'
            : null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      scrollable: true,
      title: Text('Thanh toán ${widget.application.workerName}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Đơn giá: ${money((widget.application.agreedDailyRate ?? widget.job.salaryPerDay.round()).toDouble())}/ngày. Khả dụng: ${money(widget.available.toDouble())}.',
              ),
              _number(_days, 'Số ngày công đã xác nhận', 1, 365),
              _number(_tip, 'Tiền tip (VND)', 0, 100000000),
              _number(_bonus, 'Tiền thưởng (VND)', 0, 100000000),
              const SizedBox(height: 20),
              Text(
                'Tổng thanh toán: ${money(_total.toDouble())}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (_total > widget.available)
                const Text(
                  'Số dư khả dụng không đủ. Hãy nạp tiền trước khi thanh toán.',
                  style: TextStyle(color: Colors.red),
                ),
              FormField<bool>(
                initialValue: false,
                validator: (_) =>
                    _confirmed ? null : 'Cần xác nhận nội dung thanh toán',
                builder: (state) => Column(
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _confirmed,
                      onChanged: _busy
                          ? null
                          : (v) {
                              setState(() => _confirmed = v ?? false);
                              state.didChange(_confirmed);
                            },
                      title: const Text(
                        'Đã xác nhận ngày công, tip và thưởng với thợ. Khoản đã chốt không thể sửa.',
                      ),
                    ),
                    if (state.hasError)
                      Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: _busy || _total > widget.available ? null : _submit,
          child: Text(_busy ? 'Đang thanh toán…' : 'Xác nhận thanh toán'),
        ),
      ],
    ),
  );
}
