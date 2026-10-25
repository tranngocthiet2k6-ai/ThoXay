import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController();
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  final _cccd = TextEditingController();
  String _role = 'ROLE_WORKER';
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    for (final controller in [_name, _phone, _password, _confirmation, _cccd]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.register(
        fullName: _name.text.trim(),
        phoneNumber: _phone.text.trim(),
        password: _password.text,
        role: _role,
        cccdImage: _cccd.text.trim().isEmpty ? null : _cccd.text.trim(),
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng ký')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bắt đầu kết nối',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Bạn muốn tìm việc hay tìm người thợ phù hợp?'),
                const SizedBox(height: 24),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'ROLE_WORKER',
                      label: Text('Tôi là thợ'),
                      icon: Icon(Icons.construction),
                    ),
                    ButtonSegment(
                      value: 'ROLE_CONTRACTOR',
                      label: Text('Tôi là chủ thầu'),
                      icon: Icon(Icons.apartment),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: _busy
                      ? null
                      : (value) => setState(() => _role = value.first),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Nhập họ và tên' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  enabled: !_busy,
                  maxLength: 15,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  validator: (v) =>
                      RegExp(r'^0[0-9]{9,14}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Nhập số điện thoại hợp lệ',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  validator: (v) => (v?.length ?? 0) < 8
                      ? 'Mật khẩu ít nhất 8 ký tự'
                      : utf8.encode(v!).length > 72
                      ? 'Mật khẩu tối đa 72 byte UTF-8'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmation,
                  enabled: !_busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nhập lại mật khẩu',
                  ),
                  validator: (v) => v != _password.text || (v?.isEmpty ?? true)
                      ? 'Mật khẩu nhập lại chưa khớp'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cccd,
                  enabled: !_busy,
                  maxLength: 500,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Liên kết ảnh CCCD (không bắt buộc)',
                    helperText:
                        'Liên kết HTTPS để quản trị viên kiểm tra danh tính.',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ||
                          RegExp(r'^https://[^\s]+$').hasMatch(v!.trim())
                      ? null
                      : 'Ảnh CCCD phải là liên kết HTTPS',
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Tạo tài khoản'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
