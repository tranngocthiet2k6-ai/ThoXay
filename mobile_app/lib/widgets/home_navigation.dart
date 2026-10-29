import '../theme/app_theme.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/wallet_screen.dart';

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({
    super.key,
    required this.api,
    this.worker = false,
    this.selectedIndex = 0,
    this.onSelected,
    this.onCreate,
  });
  final ApiService api;
  final bool worker;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final VoidCallback? onCreate;
  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation>
    with WidgetsBindingObserver {
  int _unread = 0;
  bool _loading = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_loading ||
        widget.api.session == null ||
        !mounted ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    _loading = true;
    try {
      final page = await widget.api.notifications();
      if (mounted) setState(() => _unread = page.unreadCount);
    } on ApiException {
      // Keep the last confirmed count; badge failures never hide the home page.
    } finally {
      _loading = false;
    }
  }

  Future<void> _select(int index) async {
    if (index < 2) {
      if (!widget.worker && index == 1) {
        widget.onCreate?.call();
      } else {
        widget.onSelected?.call(index);
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => index == 2
            ? WalletScreen(api: widget.api)
            : index == 3
            ? NotificationsScreen(api: widget.api)
            : ProfileScreen(api: widget.api),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bar = NavigationBar(
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: _select,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: Icon(
            widget.worker ? Icons.near_me_outlined : Icons.apartment_outlined,
          ),
          selectedIcon: Icon(widget.worker ? Icons.near_me : Icons.apartment),
          label: widget.worker ? 'Gần bạn' : 'Công trình',
        ),
        NavigationDestination(
          icon: Icon(
            widget.worker
                ? Icons.work_history_outlined
                : Icons.add_circle_outline,
          ),
          selectedIcon: Icon(
            widget.worker ? Icons.work_history : Icons.add_circle,
          ),
          label: widget.worker ? 'Đã ứng tuyển' : 'Tạo mới',
        ),
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Ví',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: _unread > 0,
            label: Text(_unread > 99 ? '99+' : '$_unread'),
            child: const Icon(Icons.notifications_none),
          ),
          label: 'Thông báo',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Hồ sơ',
        ),
      ],
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, bounds) {
            if (bounds.maxWidth < 840) return bar;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.roofing_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ThoXay',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(child: bar),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
