import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                    key: _form,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Color(0xff176b52),
                                  child: Icon(Icons.construction,
                                      size: 32, color: Colors.white))),
                          const SizedBox(height: 28),
                          Text('Thợ Xây',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Việc gần nhà. Thợ đúng nghề.',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text(
                              'Đăng nhập để kết nối với công trình và người thợ quanh bạn.'),
                          const SizedBox(height: 32),
                          TextFormField(
                              controller: _phone,
                              enabled: !_busy,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber
                              ],
                              maxLength: 15,
                              decoration: const InputDecoration(
                                  labelText: 'Số điện thoại',
                                  prefixIcon: Icon(Icons.phone_outlined)),
                              validator: (v) => RegExp(r'^0[0-9]{9,14}$')
                                      .hasMatch(v?.trim() ?? '')
                                  ? null
                                  : 'Nhập số điện thoại hợp lệ'),
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
                                      tooltip: _obscure
                                          ? 'Hiện mật khẩu'
                                          : 'Ẩn mật khẩu',
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(_obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined))),
                              validator: (v) => (v?.length ?? 0) >= 8
                                  ? null
                                  : 'Mật khẩu ít nhất 8 ký tự'),
                          if (_error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error))),
                          const SizedBox(height: 24),
                          FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.all(18)),
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Đăng nhập')),
                        ])),
              )),
        ))),
      );
}
