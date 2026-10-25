import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/chat_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.api,
    required this.job,
    required this.peerId,
    required this.peerName,
  });
  final ApiService api;
  final Job job;
  final int peerId;
  final String peerName;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ChatController _chat;
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  int _lastMessageId = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chat = ChatController(widget.api, widget.job.id, widget.peerId);
    _chat.addListener(_changed);
    _chat.start();
  }

  void _changed() {
    if (!mounted) return;
    final latest = _chat.messages.isEmpty ? 0 : _chat.messages.last.id;
    final scrollDown =
        latest != _lastMessageId &&
        (!_scroll.hasClients || _scroll.offset < 100);
    _lastMessageId = latest;
    setState(() {});
    if (scrollDown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _chat.reconnect();
  }

  Future<void> _send() async {
    final draft = _draft.text;
    if (await _chat.send(draft) && mounted && _draft.text == draft) {
      _draft.clear();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chat.removeListener(_changed);
    _chat.dispose();
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _time(DateTime date) {
    final local = date.toLocal();
    String two(int value) => '$value'.padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _chat.messages.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              widget.job.title,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: _chat.status == ChatStatus.connected
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(switch (_chat.status) {
                      ChatStatus.connected => 'Đã kết nối',
                      ChatStatus.connecting => 'Đang kết nối…',
                      ChatStatus.reconnecting => 'Đang kết nối lại…',
                      ChatStatus.stopped => 'Cuộc trò chuyện đã ngắt',
                    }, style: theme.textTheme.bodySmall),
                  ),
                  if (_chat.status == ChatStatus.reconnecting)
                    TextButton(
                      onPressed: _chat.reconnect,
                      child: const Text('Kết nối lại'),
                    ),
                ],
              ),
            ),
            if (_chat.error != null)
              Container(
                width: double.infinity,
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.all(12),
                child: Text(_chat.error!),
              ),
            Expanded(
              child: _chat.loading
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có tin nhắn. Hãy bắt đầu trao đổi về công việc.',
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: rows.length + (_chat.hasOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == rows.length) {
                          return TextButton(
                            onPressed: _chat.loadingOlder
                                ? null
                                : _chat.loadOlder,
                            child: Text(
                              _chat.loadingOlder
                                  ? 'Đang tải…'
                                  : 'Tải tin nhắn cũ',
                            ),
                          );
                        }
                        final message = rows[index];
                        final mine = message.senderId == _chat.userId;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            key: ValueKey('message-${message.id}'),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .8,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: mine
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(message.content),
                                const SizedBox(height: 4),
                                Text(
                                  _time(message.createdAt),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('chat-input'),
                      controller: _draft,
                      enabled: _chat.status != ChatStatus.stopped,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn…',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: IconButton.filled(
                      key: const ValueKey('chat-send'),
                      tooltip: 'Gửi tin nhắn',
                      onPressed: _chat.canSend && _draft.text.trim().isNotEmpty
                          ? _send
                          : null,
                      icon: _chat.sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
