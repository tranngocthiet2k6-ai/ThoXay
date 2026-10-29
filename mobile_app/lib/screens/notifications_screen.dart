import '../widgets/content_skeleton.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_service.dart';
import '../services/push_notifications.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.api, this.push});
  final ApiService api;
  final PushClient? push;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  late final PushClient _push = widget.push ?? PushNotifications.instance;
  final _items = <AppNotification>[];
  StreamSubscription<void>? _subscription;
  bool _loading = false,
      _loadingMore = false,
      _hasMore = false,
      _enabling = false,
      _refreshAgain = false;
  int _unread = 0, _generation = 0;
  String? _error, _pushStatus;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _push.changes.listen((_) => _refresh());
    widget.api.addListener(_authChanged);
    _refresh();
  }

  void _authChanged() {
    if (widget.api.session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    ++_generation;
    _subscription?.cancel();
    widget.api.removeListener(_authChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) {
      _refreshAgain = true;
      return;
    }
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.api.notifications();
      if (mounted && generation == _generation) {
        setState(() {
          _items
            ..clear()
            ..addAll(page.items);
          _hasMore = page.hasMore;
          _unread = page.unreadCount;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_refreshAgain) {
          _refreshAgain = false;
          unawaited(_refresh());
        }
      }
    }
  }

  Future<void> _more() async {
    if (_loading || _loadingMore || !_hasMore || _items.isEmpty) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.api.notifications(beforeId: _items.last.id);
      if (mounted && generation == _generation) {
        setState(() {
          final ids = _items.map((n) => n.id).toSet();
          _items.addAll(page.items.where((n) => !ids.contains(n.id)));
          _hasMore = page.hasMore;
          _unread = page.unreadCount;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _read(AppNotification? notification) async {
    try {
      if (notification == null) {
        await widget.api.readAllNotifications();
      } else {
        await widget.api.readNotification(notification.id);
      }
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          if (notification == null || _items[i].id == notification.id) {
            _items[i] = _items[i].markRead();
          }
        }
        _unread = notification == null
            ? 0
            : (_unread > 0 && !notification.isRead ? _unread - 1 : _unread);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _enable() async {
    setState(() => _enabling = true);
    final result = await _push.enable(widget.api);
    if (mounted) {
      setState(() {
        _enabling = false;
        _pushStatus = result;
      });
    }
  }

  IconData _icon(String type) => switch (type) {
    'CHAT_MESSAGE' => Icons.chat_bubble_outline,
    'KYC_VERIFIED' => Icons.verified_outlined,
    'JOB_COMPLETED' => Icons.star_outline,
    'APPLICATION_CANCELLED' => Icons.warning_amber_outlined,
    _ => Icons.work_outline,
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thông báo'),
      actions: [
        IconButton(
          tooltip: 'Làm mới thông báo',
          onPressed: _loading ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Không bỏ lỡ cơ hội',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pushStatus ?? 'Nhận thông báo khi có đơn ứng tuyển, tin nhắn, kết quả xác thực và đánh giá mới.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _enabling ? null : _enable,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(_enabling ? 'Đang bật…' : 'Bật thông báo đẩy'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Lịch sử · $_unread chưa đọc',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: _unread == 0 ? null : () => _read(null),
                child: const Text('Đọc tất cả'),
              ),
            ],
          ),
          if (_loading && _items.isEmpty) const ContentSkeleton(compact: true),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!_loading && _error == null && _items.isEmpty)
            EmptyState(
              icon: Icons.notifications_none,
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Kiểm tra lại'),
              ),
              title: 'Chưa có thông báo',
              message: 'Thông tin về công việc và hồ sơ của bạn sẽ xuất hiện tại đây.',
            ),
          for (final item in _items)
            Card(
              color: item.isRead
                  ? Colors.white
                  : Theme.of(context).colorScheme.primaryContainer
                        .withValues(alpha: .35),
              child: ListTile(
                key: ValueKey('notification-${item.id}'),
                contentPadding: const EdgeInsets.all(16),
                isThreeLine: true,
                leading: Icon(_icon(item.type)),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w800,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(item.body),
                    const SizedBox(height: 8),
                    Text(
                      MaterialLocalizations.of(context)
                          .formatFullDate(item.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                trailing: item.isRead
                    ? null
                    : const Icon(Icons.circle, size: 9),
                onTap: () => _read(item),
              ),
            ),
          if (_hasMore)
            TextButton(
              onPressed: _loadingMore ? null : _more,
              child: Text(_loadingMore ? 'Đang tải…' : 'Tải thông báo cũ'),
            ),
        ],
      ),
    ),
  );
}
