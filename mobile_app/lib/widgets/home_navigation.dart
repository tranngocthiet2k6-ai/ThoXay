import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/chat_inbox_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/support_center_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/appearance_controller.dart';
import 'app_snack_bar.dart';
import 'bouncing_button.dart';
import 'figma_design.dart';

/// Five destinations at every breakpoint; QR is always the central destination.
class HomeNavigation extends StatelessWidget {
  const HomeNavigation({
    super.key,
    required this.api,
    this.worker = false,
    this.selectedIndex = 0,
    this.onSelected,
  });
  final ApiService api;
  final bool worker;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  void _select(BuildContext context, int index) {
    if (index == selectedIndex) return;
    AppHaptics.light();
    onSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppPalette.of(context).surface,
      border: Border(top: BorderSide(color: AppPalette.of(context).border)),
    ),
    child: SafeArea(
      top: false,
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: NavigationBar(
            height: 86,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? AppTheme.brandInk(context)
                    : AppPalette.of(context).muted,
              ),
            ),
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _select(context, index),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: worker
                    ? const FigmaIcon('a98b9', size: 23)
                    : const Icon(Icons.apartment_outlined),
                selectedIcon: worker
                    ? FigmaIcon(
                        'c7c29',
                        size: 23,
                        color: AppTheme.brandInk(context),
                      )
                    : Icon(Icons.apartment, color: AppTheme.brandInk(context)),
                label: worker ? 'Tìm việc' : 'Công trình',
              ),
              NavigationDestination(
                icon: worker
                    ? const FigmaIcon('21a78', size: 23)
                    : const Icon(Icons.groups_outlined),
                selectedIcon: worker
                    ? FigmaIcon(
                        '21a78',
                        size: 23,
                        color: AppTheme.brandInk(context),
                      )
                    : Icon(Icons.groups, color: AppTheme.brandInk(context)),
                label: worker ? 'Việc của tôi' : 'Đội thợ',
              ),
              NavigationDestination(
                icon: Transform.translate(
                  offset: const Offset(0, -12),
                  child: Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: AppPalette.of(context).surface,
                        width: 4,
                      ),
                    ),
                    child: const FigmaIcon('80a82', size: 25),
                  ),
                ),
                label: 'Quét QR',
              ),
              NavigationDestination(
                icon: FigmaIcon(
                  'd2697',
                  size: 23,
                  color: AppPalette.of(context).muted,
                ),
                selectedIcon: FigmaIcon(
                  'c725a',
                  size: 23,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: 'Ví tiền',
              ),
              NavigationDestination(
                icon: FigmaIcon(
                  '7c86e',
                  size: 23,
                  color: AppPalette.of(context).muted,
                ),
                selectedIcon: FigmaIcon(
                  '087db',
                  size: 23,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HomeInboxActions extends StatefulWidget {
  const HomeInboxActions({super.key, required this.api});
  final ApiService api;
  @override
  State<HomeInboxActions> createState() => _HomeInboxActionsState();
}

class _HomeInboxActionsState extends State<HomeInboxActions>
    with WidgetsBindingObserver {
  int _unread = 0, _unreadChat = 0;
  int? _ownerId;
  bool _foreground = true, _loading = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _ownerId = widget.api.session?.userId;
    WidgetsBinding.instance.addObserver(this);
    widget.api.addListener(_sessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant HomeInboxActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api != widget.api) {
      oldWidget.api.removeListener(_sessionChanged);
      widget.api.addListener(_sessionChanged);
      _ownerId = widget.api.session?.userId;
      _unread = _unreadChat = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  void _sessionChanged() {
    final id = widget.api.session?.userId;
    if (_ownerId == id) return;
    setState(() {
      _ownerId = id;
      _unread = _unreadChat = 0;
    });
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.api.removeListener(_sessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refresh();
  }

  Future<void> _refresh() async {
    if (_loading ||
        !_foreground ||
        !mounted ||
        widget.api.session == null ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    _loading = true;
    final api = widget.api;
    final id = api.session!.userId;
    bool current() =>
        mounted && widget.api == api && widget.api.session?.userId == id;
    try {
      Future<void> notifications() async {
        try {
          final page = await api.notifications();
          if (current()) setState(() => _unread = page.unreadCount);
        } on ApiException {
          /* Keep the last confirmed count while offline. */
        }
      }

      Future<void> messages() async {
        try {
          final count = await api.unreadMessages();
          if (current()) setState(() => _unreadChat = count);
        } on ApiException {
          /* One failed request does not erase the other count. */
        }
      }

      await Future.wait([notifications(), messages()]);
    } finally {
      _loading = false;
      if (mounted && (widget.api != api || widget.api.session?.userId != id)) {
        _refresh();
      }
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) await _refresh();
  }

  Widget _badge(int count, IconData icon) => Badge(
    isLabelVisible: count > 0,
    label: Text(count > 99 ? '99+' : '$count'),
    child: Icon(icon),
  );

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        key: const ValueKey('home-chat-action'),
        tooltip: 'Tin nhắn',
        icon: _badge(_unreadChat, Icons.forum_outlined),
        onPressed: () => _open(ChatInboxScreen(api: widget.api)),
      ),
      IconButton(
        key: const ValueKey('home-notifications-action'),
        tooltip: 'Thông báo',
        icon: _badge(_unread, Icons.notifications_none),
        onPressed: () => _open(NotificationsScreen(api: widget.api)),
      ),
    ],
  );
}

enum _HomeAction { light, dark, outdoor, support, refresh, logout }

class HomeAppMenu extends StatelessWidget {
  const HomeAppMenu({
    super.key,
    required this.api,
    required this.onRefresh,
    this.refreshing = false,
  });
  final ApiService api;
  final Future<void> Function() onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    return PopupMenuButton<_HomeAction>(
      tooltip: 'Tùy chọn',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        switch (action) {
          case _HomeAction.light:
          case _HomeAction.dark:
          case _HomeAction.outdoor:
            final mode = switch (action) {
              _HomeAction.dark => DisplayMode.dark,
              _HomeAction.outdoor => DisplayMode.outdoor,
              _ => DisplayMode.light,
            };
            final saved = await appearance!.setMode(mode);
            if (!saved && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppSnackBar(
                  content: const Text(
                    'Đã đổi giao diện; chưa lưu được lựa chọn trên thiết bị.',
                  ),
                  kind: NoticeKind.info,
                ),
              );
            }
          case _HomeAction.support:
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SupportCenterScreen(api: api),
              ),
            );
          case _HomeAction.refresh:
            await onRefresh();
          case _HomeAction.logout:
            await api.logout();
        }
      },
      itemBuilder: (_) => [
        for (final (action, mode, label) in [
          (_HomeAction.light, DisplayMode.light, 'Chế độ Sáng'),
          (_HomeAction.dark, DisplayMode.dark, 'Chế độ Tối'),
          (
            _HomeAction.outdoor,
            DisplayMode.outdoor,
            'Tương phản cao (Ngoài trời)',
          ),
        ])
          CheckedPopupMenuItem(
            value: action,
            checked: appearance?.mode == mode,
            enabled: appearance != null,
            child: Text(label),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _HomeAction.support,
          child: Text('Trung tâm hỗ trợ & SOS'),
        ),
        PopupMenuItem(
          value: _HomeAction.refresh,
          enabled: !refreshing,
          child: const Text('Làm mới dữ liệu'),
        ),
        const PopupMenuItem(
          value: _HomeAction.logout,
          child: Text('Đăng xuất'),
        ),
      ],
    );
  }
}
