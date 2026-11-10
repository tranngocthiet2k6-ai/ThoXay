import '../widgets/bouncing_button.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'register_screen.dart';
import '../widgets/auth_shell.dart';
import '../theme/app_theme.dart';
import '../widgets/figma_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(), _password = TextEditingController();
  bool _busy = false, _obscure = true;
  String _role = 'ROLE_WORKER';
  String? _error;
  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    AppHaptics.light();
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.login(_phone.text.trim(), _password.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.forRole(
      _role,
      brightness: Theme.of(context).brightness,
      outdoor: AppPalette.of(context).outdoor,
    ),
    child: AuthShell(
      api: widget.api,
      title: 'Chào mừng bạn trở lại!',
      subtitle: 'Chọn vai trò để bắt đầu cùng Thợ Xây.',
      roleSelection: RoleCards(
        role: _role,
        onChanged: _busy ? null : (role) => setState(() => _role = role),
      ),
      child: AutofillGroup(
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
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!_busy) _submit();
                },
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                      : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RegisterScreen(api: widget.api),
                        ),
                      ),
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
