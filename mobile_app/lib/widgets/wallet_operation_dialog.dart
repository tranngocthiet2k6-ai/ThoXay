import 'dart:math';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/models.dart';

String requestId() => List.generate(
  16,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();
Future<bool?> showWalletOperation(
  BuildContext context,
  ApiService api,
  String kind,
  int available,
) => showDialog<bool>(
  context: context,
  builder: (_) => _WalletOperation(api: api, kind: kind, available: available),
);

class _WalletOperation extends StatefulWidget {
  const _WalletOperation({
    required this.api,
    required this.kind,
    required this.available,
  });
  final ApiService api;
  final String kind;
  final int available;
  @override
  State<_WalletOperation> createState() => _WalletOperationState();
}

class _WalletOperationState extends State<_WalletOperation> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _reference = TextEditingController(),
      _bank = TextEditingController(),
      _account = TextEditingController(),
      _name = TextEditingController();
  late final _id = requestId();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_amount, _reference, _bank, _account, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final amount = int.parse(_amount.text.trim());
      if (widget.kind == 'LOCK' || widget.kind == 'RELEASE') {
        await widget.api.transferEscrow({
          'direction': widget.kind,
          'amount': amount,
          'clientRequestId': _id,
        });
      } else {
        await widget.api.createWalletRequest({
          'kind': widget.kind,
          'amount': amount,
          'clientRequestId': _id,
          if (widget.kind == 'TOP_UP')
            'transferReference': _reference.text.trim(),
          if (widget.kind == 'WITHDRAW') ...{
            'bankName': _bank.text.trim(),
            'bankAccount': _account.text.trim(),
            'accountName': _name.text.trim(),
          },
        });
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.kind) {
      'TOP_UP' => 'Yêu cầu nạp tiền',
      'WITHDRAW' => 'Rút tiền nhanh',
      'LOCK' => 'Nạp ký quỹ',
      _ => 'Hoàn ký quỹ',
    };
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(title),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.kind == 'TOP_UP'
                      ? 'Chuyển tiền theo hướng dẫn của quản trị viên, sau đó gửi mã/nội dung giao dịch để đối soát. Số dư chỉ tăng khi được duyệt.'
                      : widget.kind == 'WITHDRAW'
                      ? 'Tiền được giữ chỗ ngay khi gửi yêu cầu. Quản trị viên chuyển tiền ngân hàng rồi đối soát; nếu từ chối, tiền được hoàn về số dư chính.'
                      : 'Chuyển tiền giữa số dư chính và tài khoản ký quỹ của bạn.',
                ),
                if (widget.kind != 'TOP_UP')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Khả dụng: ${money(widget.available.toDouble())}',
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('wallet-amount'),
                  controller: _amount,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền (VND)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null ||
                        !RegExp(r'^\d+$').hasMatch(v!.trim()) ||
                        n < 1000 ||
                        n > 100000000) {
                      return 'Nhập từ 1.000 đến 100.000.000đ, không có phần lẻ';
                    }
                    if (widget.kind != 'TOP_UP' && n > widget.available) {
                      return 'Số dư khả dụng không đủ';
                    }
                    return null;
                  },
                ),
                if (widget.kind == 'TOP_UP') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reference,
                    enabled: !_busy,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Mã / nội dung chuyển khoản',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                    validator: (v) => v?.trim().isNotEmpty == true
                        ? null
                        : 'Nhập mã hoặc nội dung chuyển khoản',
                  ),
                ],
                if (widget.kind == 'WITHDRAW') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bank,
                    enabled: !_busy,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Tên ngân hàng',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    validator: (v) => v?.trim().isNotEmpty == true
                        ? null
                        : 'Nhập tên ngân hàng',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _account,
                    enabled: !_busy,
                    maxLength: 34,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tài khoản',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    validator: (v) =>
                        RegExp(r'^\d{6,34}$').hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Nhập số tài khoản 6–34 chữ số',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Tên chủ tài khoản',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v?.trim().isNotEmpty == true
                        ? null
                        : 'Nhập tên chủ tài khoản',
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
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
            onPressed: _busy ? null : _submit,
            child: Text(
              _busy
                  ? 'Đang xử lý…'
                  : widget.kind == 'TOP_UP' || widget.kind == 'WITHDRAW'
                  ? 'Gửi yêu cầu'
                  : 'Xác nhận chuyển',
            ),
          ),
        ],
      ),
    );
  }
}
