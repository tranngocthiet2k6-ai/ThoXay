import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_forms.dart';
import '../widgets/auth_shell.dart';

/// Shared authentication route. Switching forms never adds a Navigator route.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.api, this.initialTab = 0})
    : assert(initialTab == 0 || initialTab == 1);
  final ApiService api;
  final int initialTab;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late int _tab = widget.initialTab;
  int _revision = 0;
  bool _busy = false, _forward = true;
  String _role = 'ROLE_WORKER';
  final _login = LoginFormDraft();
  final _registration = RegisterFormDraft();
  final _scroll = ScrollController();

  void _select(int tab) {
    if (_busy || _tab == tab) return;
    FocusScope.of(context).unfocus();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      _forward = tab > _tab;
      _tab = tab;
      _revision++;
    });
  }

  void _setBusy(bool busy) {
    if (mounted && _busy != busy) setState(() => _busy = busy);
  }

  @override
  void dispose() {
    _login.dispose();
    _registration.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.forRole(
      _tab == 1 ? _role : null,
      brightness: Theme.of(context).brightness,
      outdoor: AppPalette.of(context).outdoor,
    ),
    // The autofill session belongs to the page, not an outgoing animated form.
    child: AutofillGroup(
      child: AuthShell(
        api: widget.api,
        scrollController: _scroll,
        selectedTab: _tab,
        revision: _revision,
        forward: _forward,
        onTabChanged: _busy ? null : _select,
        title: _tab == 0 ? 'Vững tay nghề. Vững tương lai.' : 'Bắt đầu kết nối',
        subtitle: _tab == 0
            ? 'Việc gần nhà, thu nhập an tâm.'
            : 'Bạn muốn tìm việc hay tìm người thợ phù hợp?',
        child: _tab == 0
            ? LoginForm(
                api: widget.api,
                draft: _login,
                onBusyChanged: _setBusy,
                onRegister: () => _select(1),
              )
            : RegisterForm(
                api: widget.api,
                draft: _registration,
                role: _role,
                onRoleChanged: (role) => setState(() => _role = role),
                onBusyChanged: _setBusy,
              ),
      ),
    ),
  );
}
