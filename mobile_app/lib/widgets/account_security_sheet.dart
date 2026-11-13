import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'app_snack_bar.dart';
import 'bouncing_button.dart';

Future<void> showAccountSecuritySheet(
  BuildContext context,
  ApiService api, {
  bool phone = false,
}) async {
  final success = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AccountSecuritySheet(api: api, phone: phone),
  );
  if (success == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar(
        content: Text(
          phone
              ? 'Đã cập nhật số điện thoại. Các phiên cũ đã được thu hồi.'
              : 'Đổi mật khẩu thành công. Các phiên cũ đã được thu hồi.',
        ),
      ),
    );
  }
}

class AccountSecuritySheet extends StatefulWidget {
  const AccountSecuritySheet({
    super.key,
    required this.api,
    this.phone = false,
  });
  final ApiService api;
  final bool phone;
  @override
  State<AccountSecuritySheet> createState() => _AccountSecuritySheetState();
}

class _AccountSecuritySheetState extends State<AccountSecuritySheet> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController(),
      _new = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false, _obscure = true;
  String? _error;
  bool get _strong =>
      _new.text.length >= 8 &&
      RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(_new.text) &&
      RegExp(r'[0-9]').hasMatch(_new.text) &&
      utf8.encode(_new.text).length <= 72;
  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    AppHaptics.light();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.phone) {
        await widget.api.changePhone(_new.text.trim(), _old.text);
      } else {
        await widget.api.changePassword(_old.text, _new.text);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Chưa lưu được thay đổi. Kiểm tra kết nối rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.phone ? 'Đổi số điện thoại' : 'Đổi mật khẩu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.phone
                      ? 'Số mới dùng để đăng nhập và liên hệ sau khi đơn được duyệt. Xác nhận bằng mật khẩu hiện tại.'
                      : 'Chọn mật khẩu riêng cho Thợ Xây. Sau khi đổi, các phiên đăng nhập cũ sẽ hết hiệu lực.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _old,
                  enabled: !_busy,
                  obscureText: _obscure,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                      onPressed: _busy
                          ? null
                          : () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nhập mật khẩu hiện tại'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _new,
                  enabled: !_busy,
                  obscureText: !widget.phone && _obscure,
                  autocorrect: false,
                  keyboardType: widget.phone
                      ? TextInputType.phone
                      : TextInputType.visiblePassword,
                  autofillHints: [
                    widget.phone
                        ? AutofillHints.telephoneNumber
                        : AutofillHints.newPassword,
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: widget.phone
                        ? 'Số điện thoại mới'
                        : 'Mật khẩu mới',
                    prefixIcon: Icon(
                      widget.phone ? Icons.phone_outlined : Icons.key_outlined,
                    ),
                  ),
                  validator: (_) => widget.phone
                      ? (RegExp(r'^0[0-9]{9,14}$').hasMatch(_new.text.trim())
                            ? null
                            : 'Số điện thoại gồm 10–15 chữ số, bắt đầu bằng 0')
                      : (_strong
                            ? (_new.text == _old.text
                                  ? 'Mật khẩu mới phải khác mật khẩu hiện tại'
                                  : null)
                            : 'Dùng ít nhất 8 ký tự, gồm chữ và số; tối đa 72 byte'),
                ),
                if (!widget.phone) ...[
                  const SizedBox(height: 8),
                  Text(
                    _strong
                        ? 'Mật khẩu đạt yêu cầu'
                        : 'Ít nhất 8 ký tự, gồm chữ và số',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirm,
                    enabled: !_busy,
                    obscureText: _obscure,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    validator: (value) => value != _new.text
                        ? 'Mật khẩu xác nhận chưa khớp'
                        : null,
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                BouncingButton(
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(_busy ? 'Đang lưu…' : 'Lưu thay đổi'),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
