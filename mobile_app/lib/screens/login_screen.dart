import '../widgets/modern_controls.dart';
import '../widgets/bouncing_button.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'register_screen.dart';
import '../widgets/auth_shell.dart';
import '../theme/app_theme.dart';

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
      null,
      brightness: Theme.of(context).brightness,
      outdoor: AppPalette.of(context).outdoor,
    ),
    child: AuthShell(
      api: widget.api,
      title: 'Chào mừng bạn trở lại!',
      subtitle: 'Đăng nhập bằng số điện thoại của bạn.',
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
                    : const Text('Đăng nhập'),
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
