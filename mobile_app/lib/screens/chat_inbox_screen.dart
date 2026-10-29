import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_inbox.dart';
import '../services/api_service.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen>
    with WidgetsBindingObserver {
  List<ChatConversation> _rows = [];
  bool _loading = true, _busy = false, _more = false, _foreground = true;
  int _unread = 0;
  String? _error;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_foreground && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _load(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _load(silent: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool more = false, bool silent = false}) async {
    if (_busy || !mounted) return;
    _busy = true;
    if (!silent) {
      setState(() {
        _error = null;
        _loading = _rows.isEmpty;
      });
    }
    try {
      if (silent && _rows.length > 30) {
        final count = await widget.api.unreadMessages();
        if (mounted) setState(() => _unread = count);
        return;
      }
      final page = await widget.api.chatInbox(
        beforeId: more && _rows.isNotEmpty ? _rows.last.latest.id : null,
      );
      if (!mounted) return;
      setState(() {
        // Poll the first page, preserve an expanded history until explicit refresh.
        final merged = {
          if (more)
            for (final row in _rows) row.key: row,
          for (final row in page.conversations) row.key: row,
        };
        _rows = merged.values.toList()
          ..sort((a, b) => b.latest.id.compareTo(a.latest.id));
        _more = page.hasMore;
        _unread = page.unreadCount;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted && !silent) setState(() => _error = e.message);
    } finally {
      _busy = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(ChatConversation row) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          api: widget.api,
          job: row.job,
          peerId: row.peerId,
          peerName: row.peerName,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.forum_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Trao đổi công việc',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        '$_unread chưa đọc',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                if (_loading) const ContentSkeleton(chat: true),
                if (_error != null)
                  Card(
                    child: ListTile(
                      title: Text(_error!),
                      trailing: TextButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                    ),
                  ),
                if (!_loading && _error == null && _rows.isEmpty)
                  EmptyState(
                    icon: Icons.mark_chat_read_outlined,
                    title: 'Cuộc trò chuyện bắt đầu từ công trình',
                    message: 'Sau khi đơn được duyệt, chọn Nhắn tin để trao đổi với thợ hoặc chủ thầu.',
                    action: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.apartment_outlined),
                      label: const Text('Xem công trình'),
                    ),
                  ),
                for (final row in _rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _open(row),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Text(
                                  row.peerName.isEmpty
                                      ? '?'
                                      : row.peerName.characters.first
                                            .toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.peerName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: row.unreadCount > 0
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      row.job.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${row.latest.senderId == widget.api.session?.userId ? 'Bạn: ' : ''}${row.latest.kind == 'IMAGE'
                                          ? '📷 '
                                          : row.latest.kind == 'LOCATION'
                                          ? '📍 '
                                          : ''}${row.latest.content}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _time(row.latest.createdAt),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  if (row.unreadCount > 0)
                                    Badge(
                                      label: Text(
                                        row.unreadCount > 99
                                            ? '99+'
                                            : '${row.unreadCount}',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_more)
                  TextButton(
                    onPressed: _busy ? null : () => _load(more: true),
                    child: const Text('Tải thêm cuộc trò chuyện'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
