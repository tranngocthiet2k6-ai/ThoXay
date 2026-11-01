import '../theme/app_theme.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/chat_inbox_screen.dart';
import '../screens/saved_screen.dart';

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
  int _unreadChat = 0;
  bool _foreground = true;
  bool _loading = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_loading ||
        !_foreground ||
        widget.api.session == null ||
        !mounted ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    _loading = true;
    try {
      final userId = widget.api.session!.userId;
      Future<void> notifications() async {
        try {
          final page = await widget.api.notifications();
          if (mounted && widget.api.session?.userId == userId) {
            setState(() => _unread = page.unreadCount);
          }
        } on ApiException {
          /* Retain the last confirmed count. */
        }
      }

      Future<void> messages() async {
        try {
          final count = await widget.api.unreadMessages();
          if (mounted && widget.api.session?.userId == userId) {
            setState(() => _unreadChat = count);
          }
        } on ApiException {
          /* Retain the last confirmed count. */
        }
      }

      await Future.wait([notifications(), messages()]);
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
            : index == 5
            ? ChatInboxScreen(api: widget.api)
            : ProfileScreen(api: widget.api),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final bar = NavigationBar(
      selectedIndex: wide
          ? widget.selectedIndex
          : widget.selectedIndex > 2
          ? 3
          : widget.selectedIndex,
      onDestinationSelected: (index) {
        if (!wide && index == 3) {
          _select(4);
          return;
        }
        if (!widget.worker && index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SavedScreen(api: widget.api, worker: false),
            ),
          );
          return;
        }
        _select(index);
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: Icon(
            widget.worker ? Icons.near_me_outlined : Icons.apartment_outlined,
          ),
          selectedIcon: Icon(widget.worker ? Icons.near_me : Icons.apartment),
          label: widget.worker ? 'Tìm việc' : 'Công trình',
        ),
        NavigationDestination(
          icon: Icon(
            widget.worker ? Icons.work_history_outlined : Icons.groups_outlined,
          ),
          selectedIcon: Icon(widget.worker ? Icons.work_history : Icons.groups),
          label: widget.worker ? 'Việc của tôi' : 'Đội thợ',
        ),
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Ví tiền',
        ),
        if (wide)
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text(_unread > 99 ? '99+' : '$_unread'),
              child: const Icon(Icons.notifications_none),
            ),
            label: 'Thông báo',
          ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: !wide && _unread + _unreadChat > 0,
            label: Text(
              _unread + _unreadChat > 99 ? '99+' : '${_unread + _unreadChat}',
            ),
            child: const Icon(Icons.person_outline),
          ),
          label: 'Hồ sơ',
        ),
        if (wide)
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadChat > 0,
              label: Text(_unreadChat > 99 ? '99+' : '$_unreadChat'),
              child: const Icon(Icons.forum_outlined),
            ),
            label: 'Tin nhắn',
          ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        border: Border(top: BorderSide(color: AppPalette.of(context).border)),
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

class HomeInboxActions extends StatelessWidget {
  const HomeInboxActions({super.key, required this.api});
  final ApiService api;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Tin nhắn',
        icon: const Icon(Icons.forum_outlined),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ChatInboxScreen(api: api)),
        ),
      ),
      IconButton(
        tooltip: 'Thông báo',
        icon: const Icon(Icons.notifications_none),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsScreen(api: api),
          ),
        ),
      ),
    ],
  );
}
