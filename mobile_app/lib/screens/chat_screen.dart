import '../widgets/bouncing_button.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/chat_contact.dart';
import '../services/chat_controller.dart';
import '../services/device_photo_picker.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/chat_attachment_dialog.dart';
import '../widgets/chat_call_sheet.dart';
import '../widgets/chat_ui.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/job_card.dart';
import 'commitment_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.api,
    required this.job,
    required this.peerId,
    required this.peerName,
    this.picker,
    this.location,
    this.embedded = false,
    this.onRead,
  });
  final ApiService api;
  final Job job;
  final int peerId;
  final String peerName;
  final DevicePhotoPicker? picker;
  final LocationService? location;
  final bool embedded;
  final VoidCallback? onRead;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ChatController _chat;
  final _draft = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  ChatContact? _contact;
  int _lastMessageId = 0, _lastRead = 0;
  bool _reading = false, _foreground = true, _calling = false;
  static const _replies = [
    'Tôi đang tới công trình',
    'Đã có mặt tại công trường',
    'Đã gửi ảnh nghiệm thu',
    'Nhờ anh kiểm tra nghiệm thu giúp',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chat = ChatController(widget.api, widget.job.id, widget.peerId);
    _chat.addListener(_changed);
    _scroll.addListener(_markVisible);
    _chat.start();
    _loadContact();
  }

  Future<void> _loadContact() async {
    try {
      final contact = await loadChatContact(
        widget.api,
        widget.job,
        widget.peerId,
      );
      if (mounted && _chat.status != ChatStatus.stopped) {
        setState(() => _contact = contact);
      }
    } on ApiException {
      /* Chat remains usable when optional contact data is offline. */
    }
  }

  void _changed() {
    if (!mounted) return;
    final latest = _chat.messages.isEmpty ? 0 : _chat.messages.last.id;
    final scrollDown =
        latest != _lastMessageId &&
        (!_scroll.hasClients || _scroll.offset < 100);
    _lastMessageId = latest;
    setState(() {
      if (_chat.status == ChatStatus.stopped) _contact = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _markVisible());
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
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _chat.reconnect();
      _loadContact();
    }
  }

  Future<void> _markVisible() async {
    if (!mounted ||
        _reading ||
        !_foreground ||
        _chat.loading ||
        _chat.messages.isEmpty ||
        !(ModalRoute.of(context)?.isCurrent ?? true) ||
        (_scroll.hasClients && _scroll.offset > 8)) {
      return;
    }
    final latest = _chat.messages.last.id;
    if (latest <= _lastRead) return;
    _reading = true;
    try {
      await widget.api.readMessages(widget.job.id, widget.peerId, latest);
      if (!mounted) return;
      _lastRead = latest;
      widget.onRead?.call();
    } on ApiException {
      /* Retry only when this conversation is actually visible. */
    } finally {
      _reading = false;
      if (mounted &&
          _lastRead == latest &&
          _chat.messages.isNotEmpty &&
          _chat.messages.last.id > latest) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _markVisible());
      }
    }
  }

  Future<void> _send() async {
    final draft = _draft.text;
    if (await _chat.send(draft) && mounted && _draft.text == draft) {
      _draft.clear();
      setState(() {});
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
    if (mounted) _markVisible();
  }

  Future<void> _call() async {
    if (_calling || _chat.status == ChatStatus.stopped) return;
    setState(() => _calling = true);
    try {
      await showChatCallSheet(
        context,
        api: widget.api,
        job: widget.job,
        peerId: widget.peerId,
        peerName: widget.peerName,
        logCall: (key) => _chat.sendMedia(
          () => widget.api.sendMessage(
            widget.job.id,
            widget.peerId,
            simulatedCallLog,
            key,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  Future<void> _openJob() async {
    try {
      final contact = await loadChatContact(
        widget.api,
        widget.job,
        widget.peerId,
      );
      if (!mounted) return;
      if (contact == null) {
        await showJobDetails<void>(context, widget.job);
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CommitmentScreen(
              api: widget.api,
              applicationId: contact.application.id,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      _notice(e.message);
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar(content: Text(text), kind: NoticeKind.error));
    }
  }

  Future<void> _openLocation(double lat, double lng) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
    });
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } on Object {
      /* Keep the conversation available without a map handler. */
    }
    _notice('Không mở được bản đồ. Hãy thử lại.');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chat.removeListener(_changed);
    _chat.dispose();
    _draft.dispose();
    _focus.dispose();
    _scroll.removeListener(_markVisible);
    _scroll.dispose();
    super.dispose();
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppPalette.of(context).surface,
      child: SafeArea(
        bottom: false,
        top: !widget.embedded,
        child: Padding(
          padding: EdgeInsets.fromLTRB(widget.embedded ? 16 : 4, 8, 8, 8),
          child: Row(
            children: [
              if (!widget.embedded) const BackButton(),
              ChatAvatar(
                name: widget.peerName,
                connected: _chat.status == ChatStatus.connected,
                statusLabel: 'Kết nối tới máy chủ trò chuyện; chưa có dữ liệu online của đối phương',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.peerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (_contact?.verified == true)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Đã KYC',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    Text(
                      switch (_chat.status) {
                        ChatStatus.connected => 'Đã kết nối',
                        ChatStatus.connecting => 'Đang kết nối…',
                        ChatStatus.reconnecting => 'Đang kết nối lại…',
                        ChatStatus.stopped => 'Cuộc trò chuyện đã ngắt',
                      },
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppPalette.of(context).muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Phiếu cam kết / Chi tiết việc',
                onPressed: _openJob,
                icon: const Icon(Icons.description_outlined),
              ),
              IconButton.filledTonal(
                tooltip: 'Gọi điện',
                onPressed: _calling || _chat.status == ChatStatus.stopped
                    ? null
                    : _call,
                icon: const Icon(Icons.call_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jobBanner(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final phone = _contact?.phone;
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: .06),
      child: InkWell(
        onTap: _openJob,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.apartment_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${money(_contact?.dailyRate ?? widget.job.salaryPerDay)}/ngày',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          statusLabel(widget.job.status),
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                      ],
                    ),
                    if (phone != null && phone.isNotEmpty)
                      Text(
                        'Liên hệ: $phone',
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messages(BuildContext context) {
    if (_chat.loading) {
      return const SingleChildScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: ContentSkeleton(chat: true),
      );
    }
    final rows = _chat.messages.reversed.toList();
    if (rows.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.forum_outlined,
            title: 'Bắt đầu cuộc trò chuyện',
            message: 'Trao đổi rõ ràng hôm nay, phối hợp nhịp nhàng ngày mai.',
            action: BouncingButton(
              child: FilledButton.icon(
                icon: const Icon(Icons.waving_hand_outlined),
                label: const Text('Soạn lời chào'),
                onPressed: _chat.status == ChatStatus.stopped
                    ? null
                    : () {
                        _draft.text =
                            'Xin chào, tôi muốn trao đổi về công trình này.';
                        _focus.requestFocus();
                        setState(() {});
                      },
              ),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      key: const ValueKey('chat-messages'),
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rows.length + (_chat.hasOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return TextButton(
            onPressed: _chat.loadingOlder ? null : _chat.loadOlder,
            child: Text(_chat.loadingOlder ? 'Đang tải…' : 'Tải tin nhắn cũ'),
          );
        }
        final message = rows[index];
        final firstOfDay =
            index == rows.length - 1 ||
            chatDay(rows[index + 1].createdAt) != chatDay(message.createdAt);
        return Column(
          children: [
            if (firstOfDay) ChatDayDivider(date: message.createdAt),
            ChatMessageBubble(
              api: widget.api,
              message: message,
              mine: message.senderId == _chat.userId,
              peerName: widget.peerName,
              peerLastReadMessageId: _chat.peerLastReadMessageId,
              onLocation: _openLocation,
            ),
          ],
        );
      },
    );
  }

  Widget _composer(BuildContext context) => Material(
    color: AppPalette.of(context).surface,
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                for (final reply in _replies)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(reply),
                      onPressed: _chat.status == ChatStatus.stopped
                          ? null
                          : () {
                              _draft.text = reply;
                              _focus.requestFocus();
                              setState(() {});
                            },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Đính kèm ảnh hoặc vị trí',
                  enabled: _chat.canSend,
                  onSelected: _attach,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
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
                IconButton(
                  tooltip: 'Gửi tọa độ hiện tại',
                  onPressed: _chat.canSend ? () => _attach('gps') : null,
                  icon: const Icon(Icons.location_on_outlined),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('chat-input'),
                    controller: _draft,
                    focusNode: _focus,
                    enabled: _chat.status != ChatStatus.stopped,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn…',
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
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
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        _header(context),
        _jobBanner(context),
        if (_chat.error != null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _chat.error!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_chat.status == ChatStatus.reconnecting)
                  TextButton(
                    onPressed: _chat.reconnect,
                    child: const Text('Kết nối lại'),
                  ),
              ],
            ),
          ),
        Expanded(child: _messages(context)),
        _composer(context),
      ],
    );
    if (widget.embedded) {
      return ColoredBox(color: AppPalette.of(context).canvas, child: body);
    }
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: body,
        ),
      ),
    );
  }
}
