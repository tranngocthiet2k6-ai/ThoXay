import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/deposit.dart';
import '../models/models.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import 'wallet_operation_dialog.dart';
import 'app_snack_bar.dart';

class DepositDialog extends StatefulWidget {
  const DepositDialog({super.key, required this.api, this.requestId});
  final ApiService api;
  final int? requestId;
  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final _amount = TextEditingController();
  final _form = GlobalKey<FormState>();
  late final _clientId = requestId();
  Deposit? _deposit;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    if (widget.requestId != null) _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await widget.api.deposit(widget.requestId!);
      if (mounted) setState(() => _deposit = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await widget.api.createDeposit(
        int.parse(_amount.text.trim()),
        _clientId,
      );
      if (mounted) setState(() => _deposit = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _copy(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: SelectableText(
      value,
      style: Theme.of(context).textTheme.titleMedium,
    ),
    trailing: IconButton(
      tooltip: 'Sao chép $label',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar(content: Text('Đã sao chép ${label.toLowerCase()}.')),
          );
        }
      },
      icon: const Icon(Icons.copy_outlined),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Nạp tiền bằng VietQR'),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_deposit == null && widget.requestId == null)
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tạo QR chứa sẵn số tiền và nội dung đối soát. Số dư được cộng sau khi Admin xác nhận đã nhận tiền.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('deposit-amount'),
                      controller: _amount,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền nạp',
                        suffixText: 'đ',
                      ),
                      validator: (v) {
                        final amount = int.tryParse(v?.trim() ?? '');
                        return amount == null ||
                                amount < 1000 ||
                                amount > 100000000
                            ? 'Nhập từ 1.000 đến 100.000.000đ'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
            if (_deposit case final d?) ...[
              if (d.isDemo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'CHẾ ĐỘ DEMO · KHÔNG CHUYỂN TIỀN',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text(
                money(d.amount.toDouble()),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (d.status == 'PENDING')
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: QrImageView(
                      data: d.payload,
                      size: 260,
                      backgroundColor: Colors.white,
                    ),
                  ),
                )
              else
                Chip(label: Text(requestStatus(d.status))),
              _copy('Ngân hàng', d.bankName),
              _copy('Số tài khoản', d.accountNo),
              _copy('Tên người nhận', d.accountName),
              _copy('Nội dung chuyển khoản', d.reference),
              Text(
                d.isDemo
                    ? 'QR minh họa dùng ngân hàng mô phỏng. Không mở ứng dụng ngân hàng để chuyển tiền theo mã này. Mọi số dư và đối soát trong demo đều là dữ liệu thử nghiệm.'
                    : d.status == 'PENDING'
                    ? 'Kiểm tra người nhận trong ứng dụng ngân hàng, chuyển đúng số tiền và giữ nguyên nội dung. Sau chuyển tiền, theo dõi trạng thái chờ đối soát trong lịch sử yêu cầu.'
                    : 'Yêu cầu này đã được xử lý. Xem kết quả đối soát trong lịch sử ví.',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () => Navigator.pop(context, _deposit != null),
          child: const Text('Đóng'),
        ),
        if (_deposit == null && widget.requestId == null)
          FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Tạo QR nạp tiền'),
          ),
        if (_deposit == null && widget.requestId != null)
          FilledButton(
            onPressed: _busy ? null : _load,
            child: const Text('Thử lại'),
          ),
      ],
    ),
  );
}
