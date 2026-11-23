import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'bouncing_button.dart';
import 'figma_components.dart';
import 'figma_design.dart';
import 'modern_controls.dart';

/// Auth drafts are held only for the lifetime of the shared authentication page.
class LoginFormDraft {
  final phone = TextEditingController(), password = TextEditingController();
  void dispose() {
    phone.dispose();
    password.dispose();
  }
}

class RegisterFormDraft {
  final name = TextEditingController(), phone = TextEditingController();
  final password = TextEditingController(),
      confirmation = TextEditingController();
  void dispose() {
    for (final controller in [name, phone, password, confirmation]) {
      controller.dispose();
    }
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.api,
    required this.draft,
    required this.onRegister,
    required this.onBusyChanged,
  });
  final ApiService api;
  final LoginFormDraft draft;
  final VoidCallback onRegister;
  final ValueChanged<bool> onBusyChanged;
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _form = GlobalKey<FormState>();
  TextEditingController get _phone => widget.draft.phone;
  TextEditingController get _password => widget.draft.password;
  bool _busy = false, _obscure = true;
  String? _error;
  Future<void> _submit() async {
    if (_busy) return;
    AppHaptics.light();
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyChanged(true);
    try {
      await widget.api.login(_phone.text.trim(), _password.text);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phone,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            maxLength: 15,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              counterText: '',
              prefixIcon: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: FigmaIcon('ca52f', size: 19),
              ),
            ),
            validator: (v) =>
                RegExp(r'^0[0-9]{9,14}$').hasMatch(v?.trim() ?? '')
                ? null
                : 'Nhập số điện thoại hợp lệ',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) {
              if (!_busy) _submit();
            },
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Center(
                widthFactor: 1,
                heightFactor: 1,
                child: FigmaIcon('3bdfd', size: 19),
              ),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: const FigmaIcon('17efc', size: 19),
              ),
            ),
            validator: (v) =>
                (v?.length ?? 0) >= 8 ? null : 'Mật khẩu ít nhất 8 ký tự',
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hỗ trợ lấy lại quyền truy cập'),
                        content: const Text(
                          'Ứng dụng chưa hỗ trợ đặt lại mật khẩu tự động. Hãy liên hệ quản trị viên đã cấp hoặc hỗ trợ tài khoản để được xác minh danh tính. Không gửi mật khẩu hay mã OTP cho người khác.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Đã hiểu'),
                          ),
                        ],
                      ),
                    ),
              child: const Text('Quên mật khẩu?'),
            ),
          ),
          GradientPrimaryButton(
            flat: true,
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Đăng nhập'),
                      SizedBox(width: 10),
                      FigmaIcon('ad551', size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : widget.onRegister,
            child: const Text('Chưa có tài khoản? Đăng ký'),
          ),
        ],
      ),
    ),
  );
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    super.key,
    required this.api,
    required this.draft,
    required this.role,
    required this.onRoleChanged,
    required this.onBusyChanged,
  });
  final ApiService api;
  final RegisterFormDraft draft;
  final String role;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<bool> onBusyChanged;
  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _form = GlobalKey<FormState>();
  TextEditingController get _name => widget.draft.name;
  TextEditingController get _phone => widget.draft.phone;
  TextEditingController get _password => widget.draft.password;
  TextEditingController get _confirmation => widget.draft.confirmation;
  String get _role => widget.role;
  String? _error;
  bool _busy = false;
  Future<void> _submit() async {
    if (_busy) return;
    AppHaptics.light();
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyChanged(true);
    try {
      await widget.api.register(
        fullName: _name.text.trim(),
        phoneNumber: _phone.text.trim(),
        password: _password.text,
        role: _role,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RoleCards(role: _role, onChanged: _busy ? null : widget.onRoleChanged),
      const SizedBox(height: 20),
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_outline),
              ),
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
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
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
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
              ),
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
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (v) => v != _password.text || (v?.isEmpty ?? true)
                  ? 'Mật khẩu nhập lại chưa khớp'
                  : null,
            ),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.camera_alt_outlined),
              title: Text('Xác thực CCCD bằng camera'),
              subtitle: Text(
                'Sau khi đăng ký, mở Hồ sơ & CCCD để chụp đủ hai mặt và gửi xác thực.',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            BouncingButton(
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tạo tài khoản'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ],
  );
}
