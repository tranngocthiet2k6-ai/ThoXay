import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/content_skeleton.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/chat_controller.dart';
import '../widgets/job_card.dart';
import '../widgets/private_image.dart';
import '../widgets/chat_attachment_dialog.dart';
import '../services/device_photo_picker.dart';
import '../services/location_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.api,
    required this.job,
    required this.peerId,
    required this.peerName,
    this.picker,
    this.location,
  });
  final ApiService api;
  final Job job;
  final int peerId;
  final String peerName;
  final DevicePhotoPicker? picker;
  final LocationService? location;
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

  Future<void> _attach(String kind) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChatAttachmentDialog(
        chat: _chat,
        source: kind == 'gps'
            ? null
            : kind == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery,
        picker: widget.picker,
        location: widget.location,
      ),
    );
  }

  Future<void> _openLocation(double lat, double lng) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
    });
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* Report an unavailable map app without breaking chat. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được bản đồ. Hãy thử lại.')),
      );
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ListTile(
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(
                      widget.job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${money(widget.job.salaryPerDay)} / ngày · ${widget.job.jobType}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showJobDetails<void>(context, widget.job),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                      ? const SingleChildScrollView(
                          child: ContentSkeleton(chat: true),
                        )
                      : rows.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: EmptyState(
                              icon: Icons.forum_outlined,
                              title: 'Bắt đầu cuộc trò chuyện',
                              message: 'Chưa có tin nhắn. Hãy bắt đầu trao đổi về công việc.',
                              action: FilledButton.icon(
                                icon: const Icon(Icons.waving_hand_outlined),
                                label: const Text('Soạn lời chào'),
                                onPressed: _chat.status == ChatStatus.stopped
                                    ? null
                                    : () {
                                        _draft.text = 'Xin chào, tôi muốn trao đổi về công trình này.';
                                        setState(() {});
                                      },
                              ),
                            ),
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
                                  maxWidth:
                                      (MediaQuery.sizeOf(context).width
                                                  .clamp(0, 960) *
                                              .8)
                                          .toDouble(),
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? theme.colorScheme.primaryContainer
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(mine ? 20 : 4),
                                    bottomRight: Radius.circular(mine ? 4 : 20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (message.kind == 'IMAGE' &&
                                        message.imagePath != null) ...[
                                      Semantics(
                                        label: 'Phóng to ảnh công trường',
                                        button: true,
                                        child: InkWell(
                                          onTap: () => showPrivatePhoto(
                                            context,
                                            widget.api,
                                            message.imagePath!,
                                            message.content,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: SizedBox(
                                              width: 260,
                                              height: 190,
                                              child: PrivateImage(
                                                api: widget.api,
                                                path: message.imagePath!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (message.kind == 'LOCATION' &&
                                        message.latitude != null &&
                                        message.longitude != null)
                                      OutlinedButton.icon(
                                        onPressed: () => _openLocation(
                                          message.latitude!,
                                          message.longitude!,
                                        ),
                                        icon: const Icon(
                                          Icons.location_on_outlined,
                                        ),
                                        label: const Text(
                                          'Mở vị trí trên bản đồ',
                                        ),
                                      ),
                                    Text(message.content),
                                    if (message.kind == 'LOCATION' &&
                                        message.latitude != null &&
                                        message.longitude != null)
                                      Text(
                                        '${message.latitude!.toStringAsFixed(5)}, ${message.longitude!.toStringAsFixed(5)}',
                                        style: theme.textTheme.bodySmall,
                                      ),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: PopupMenuButton<String>(
                          tooltip: 'Đính kèm ảnh hoặc vị trí',
                          enabled: _chat.canSend,
                          onSelected: _attach,
                          icon: const Icon(Icons.add_circle_outline),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'camera',
                              child: Text('Chụp ảnh công trường'),
                            ),
                            PopupMenuItem(
                              value: 'gallery',
                              child: Text('Chọn ảnh từ thư viện'),
                            ),
                            PopupMenuItem(
                              value: 'gps',
                              child: Text('Chia sẻ vị trí GPS'),
                            ),
                          ],
                        ),
                      ),
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
                          onPressed:
                              _chat.canSend && _draft.text.trim().isNotEmpty
                              ? _send
                              : null,
                          icon: _chat.sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
        ),
      ),
    );
  }
}
