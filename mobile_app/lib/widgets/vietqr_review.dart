import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/qr_action.dart';
import '../models/models.dart';
import 'app_snack_bar.dart';

class VietQrReview extends StatefulWidget {
  const VietQrReview({
    super.key,
    required this.payment,
    this.launcher,
    this.bankResolver,
  });
  final VietQrPayment payment;
  final Future<bool> Function(Uri)? launcher;
  final Future<String?> Function(String)? bankResolver;
  @override
  State<VietQrReview> createState() => _VietQrReviewState();
}

class _VietQrReviewState extends State<VietQrReview> {
  final _amount = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _bankCode, _error;
  String _app = 'icb';
  bool _loading = true, _opening = false;
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    try {
      String? code;
      if (widget.bankResolver != null) {
        code = await widget.bankResolver!(widget.payment.bankBin);
      } else {
        final response = await http
            .get(Uri.https('api.vietqr.io', '/v2/banks'))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final j = jsonDecode(utf8.decode(response.bodyBytes));
          if (j is Map && j['data'] is List) {
            for (final bank in j['data'] as List) {
              if (bank is Map &&
                  bank['bin'] == widget.payment.bankBin &&
                  bank['code'] is String) {
                code = (bank['code'] as String).toLowerCase();
                break;
              }
            }
          }
        }
      }
      if (mounted) {
        setState(
          () => _bankCode =
              code != null && RegExp(r'^[a-z0-9]{2,20}$').hasMatch(code)
              ? code
              : null,
        );
      }
    } catch (_) {
      /* Keep the QR and copy actions available when bank lookup is offline. */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open() async {
    if (_opening || _bankCode == null || !_form.currentState!.validate()) {
      return;
    }
    final amount = widget.payment.amount ?? int.parse(_amount.text.trim());
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final uri = widget.payment.bankLink(_app, _bankCode!, amount);
      final opened =
          await (widget.launcher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened && mounted) {
        setState(
          () => _error = 'Chưa mở được ứng dụng ngân hàng. Sao chép thông tin hoặc dùng trình quét QR trong ứng dụng ngân hàng.',
        );
      }
    } on PlatformException {
      if (mounted) {
        setState(
          () => _error = 'Thiết bị chưa hỗ trợ mở ngân hàng. Hãy sao chép thông tin chuyển khoản.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đối chiếu VietQR',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SelectableText(
              'Ngân hàng (BIN): ${widget.payment.bankBin}\nTài khoản: ${widget.payment.accountNo}\nNội dung: ${widget.payment.reference}',
            ),
            if (widget.payment.accountName.isNotEmpty)
              Text('Tên trong QR: ${widget.payment.accountName}'),
            const SizedBox(height: 16),
            if (widget.payment.amount != null)
              Text(
                money(widget.payment.amount!.toDouble()),
                style: Theme.of(context).textTheme.headlineSmall,
              )
            else
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền chuyển (đồng)',
                ),
                validator: (v) {
                  final amount = int.tryParse(v?.trim() ?? '');
                  return amount == null || amount < 1 || amount > 9999999999999
                      ? 'Nhập số tiền hợp lệ'
                      : null;
                },
              ),
            const SizedBox(height: 16),
            const Text(
              'Kiểm tra lại tên người thụ hưởng trong ứng dụng ngân hàng trước khi xác nhận. Quét QR hoặc mở ngân hàng chưa xác nhận thanh toán; ví chỉ ghi nhận sau đối soát của Admin.',
            ),
            const SizedBox(height: 16),
            if (widget.payment.demo)
              const Text(
                'Đây là ngân hàng mẫu dùng để demo. Không chuyển tiền thật.',
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _app,
                decoration: const InputDecoration(
                  labelText: 'Ứng dụng dùng để chuyển tiền',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'icb',
                    child: Text('VietinBank iPay'),
                  ),
                  DropdownMenuItem(
                    value: 'bidv',
                    child: Text('BIDV SmartBanking'),
                  ),
                  DropdownMenuItem(value: 'acb', child: Text('ACB ONE')),
                  DropdownMenuItem(value: 'mb', child: Text('MBBank')),
                ],
                onChanged: (v) => setState(() => _app = v!),
              ),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(),
              if (!_loading && _bankCode == null)
                const Text(
                  'Chưa tra được ngân hàng nhận. Bạn có thể sao chép thông tin để chuyển khoản trong ứng dụng ngân hàng.',
                ),
              FilledButton.icon(
                onPressed: _loading || _opening || _bankCode == null
                    ? null
                    : _open,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở ứng dụng ngân hàng'),
              ),
            ],
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text:
                        'BIN ${widget.payment.bankBin}\n${widget.payment.accountNo}\n${widget.payment.amount ?? ""}\n${widget.payment.reference}',
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppSnackBar(
                      content: const Text(
                        'Đã sao chép thông tin chuyển khoản.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Sao chép thông tin'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    ),
  );
}
