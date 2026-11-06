import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_inbox.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_call_sheet.dart';
import '../widgets/chat_ui.dart';
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
  final _search = TextEditingController();
  String _query = '';
  ChatConversation? _selected;
  String? _callingKey;
  bool _onlyUnread = false,
      _loading = true,
      _busy = false,
      _more = false,
      _foreground = true;
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
    _search.dispose();
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
    final session = widget.api.session?.token;
    try {
      final page = await widget.api.chatInbox(
        beforeId: more && _rows.isNotEmpty ? _rows.last.latest.id : null,
      );
      if (!mounted || widget.api.session?.token != session) return;
      setState(() {
        // A background first-page refresh must not discard older loaded rooms.
        final merged = {
          if (more || silent)
            for (final row in _rows) row.key: row,
          for (final row in page.conversations) row.key: row,
        };
        _rows = merged.values.toList()
          ..sort((a, b) => b.latest.id.compareTo(a.latest.id));
        if (!silent || _rows.length <= 30) _more = page.hasMore;
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

  Future<void> _open(ChatConversation row, bool wide) async {
    if (wide) {
      setState(() => _selected = row);
      return;
    }
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

  Future<void> _call(ChatConversation row) async {
    if (_callingKey != null) return;
    setState(() => _callingKey = row.key);
    try {
      await showChatCallSheet(
        context,
        api: widget.api,
        job: row.job,
        peerId: row.peerId,
        peerName: row.peerName,
      );
      if (mounted) await _load(silent: true);
    } finally {
      if (mounted) setState(() => _callingKey = null);
    }
  }

  Widget _item(ChatConversation row, bool wide) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final mine = row.latest.senderId == widget.api.session?.userId;
    final preview = switch (row.latest.kind) {
      'IMAGE' => '[Hình ảnh]',
      'LOCATION' => '[Vị trí GPS]',
      _ => row.latest.content,
    };
    return Material(
      color: wide && _selected?.key == row.key
          ? theme.colorScheme.primary.withValues(alpha: .09)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Mở cuộc trò chuyện với ${row.peerName}',
              child: InkWell(
                key: ValueKey('conversation-${row.key}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () => _open(row, wide),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ChatAvatar(name: row.peerName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.peerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: row.unreadCount > 0
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _time(row.latest.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: .08,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                row.job.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${mine ? 'Bạn: ' : ''}$preview',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: row.unreadCount > 0
                                          ? palette.ink
                                          : palette.muted,
                                      fontWeight: row.unreadCount > 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (row.unreadCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Badge(
                                      backgroundColor: const Color(0xFFDC2626),
                                      textColor: Colors.white,
                                      label: Text(
                                        row.unreadCount > 99
                                            ? '99+'
                                            : '${row.unreadCount}',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Gọi ${row.peerName}',
            visualDensity: VisualDensity.compact,
            onPressed: _callingKey == null ? () => _call(row) : null,
            icon: const Icon(Icons.call_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _inbox(bool wide) {
    final filtered = _rows
        .where(
          (row) =>
              (!_onlyUnread || row.unreadCount > 0) &&
              '${row.peerName} ${row.job.title}'.toLowerCase().contains(
                _query.trim().toLowerCase(),
              ),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trao đổi công việc',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '$_unread chưa đọc',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('inbox-search'),
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Tìm tên hoặc công trình...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: !_onlyUnread,
                    onSelected: (_) => setState(() => _onlyUnread = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Chưa đọc'),
                    selected: _onlyUnread,
                    onSelected: (_) => setState(() => _onlyUnread = true),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              key: const ValueKey('inbox-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              children: [
                if (_loading) const ContentSkeleton(chat: true),
                if (_error != null)
                  ListTile(
                    title: Text(_error!),
                    trailing: TextButton(
                      onPressed: _load,
                      child: const Text('Thử lại'),
                    ),
                  ),
                if (!_loading && _error == null && _rows.isEmpty)
                  EmptyState(
                    icon: Icons.mark_chat_read_outlined,
                    title: 'Cuộc trò chuyện bắt đầu từ công trình',
                    message: 'Sau khi đơn được duyệt, chọn Nhắn tin để trao đổi với thợ hoặc chủ thầu.',
                    action: FilledButton.icon(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.apartment_outlined),
                      label: const Text('Xem công trình'),
                    ),
                  ),
                if (!_loading && _rows.isNotEmpty && filtered.isEmpty)
                  EmptyState(
                    icon: Icons.search_off,
                    title: 'Chưa tìm thấy cuộc trò chuyện',
                    message: 'Thử tên khác hoặc xem tất cả tin nhắn.',
                    action: TextButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {
                          _query = '';
                          _onlyUnread = false;
                        });
                      },
                      child: const Text('Xóa bộ lọc'),
                    ),
                  ),
                for (final row in filtered) _item(row, wide),
                if (_more)
                  TextButton(
                    onPressed: _busy ? null : () => _load(more: true),
                    child: const Text('Tải thêm cuộc trò chuyện'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tin nhắn')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: LayoutBuilder(
          builder: (context, bounds) {
            if (bounds.maxWidth < 840) return _inbox(false);
            final selected = _selected;
            return Row(
              key: const ValueKey('chat-split-view'),
              children: [
                SizedBox(width: 340, child: _inbox(true)),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppPalette.of(context).border,
                ),
                Expanded(
                  child: selected == null
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: EmptyState(
                              icon: Icons.forum_outlined,
                              title: 'Chọn cuộc trò chuyện',
                              message: 'Công việc rõ ràng hơn từ những trao đổi gần gũi.',
                              action: _rows.isEmpty
                                  ? null
                                  : TextButton(
                                      onPressed: () => _open(_rows.first, true),
                                      child: const Text('Mở tin nhắn gần nhất'),
                                    ),
                            ),
                          ),
                        )
                      : ChatScreen(
                          key: ValueKey(selected.key),
                          api: widget.api,
                          job: selected.job,
                          peerId: selected.peerId,
                          peerName: selected.peerName,
                          embedded: true,
                          onRead: () => _load(silent: true),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  String _time(DateTime value) {
    if (chatDay(value) == 'Hôm nay') return chatTime(value);
    if (chatDay(value) == 'Hôm qua') return 'Hôm qua';
    final local = value.toLocal();
    return '${local.day}/${local.month}';
  }
}
