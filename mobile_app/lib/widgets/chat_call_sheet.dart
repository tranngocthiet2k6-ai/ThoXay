import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/chat_contact.dart';
import 'app_snack_bar.dart';
import 'chat_ui.dart';

const simulatedCallLog = '📞 Cuộc gọi thoại • Đã liên hệ (mô phỏng)';

/// Re-check acceptance on every call, including the quick action in the inbox.
Future<void> showChatCallSheet(
  BuildContext context, {
  required ApiService api,
  required Job job,
  required int peerId,
  required String peerName,
  Future<bool> Function(String clientMessageId)? logCall,
  Future<bool> Function(Uri)? launcher,
}) async {
  final session = api.session;
  if (session == null) return;
  try {
    final contact = await loadChatContact(api, job, peerId);
    if (!context.mounted || api.session?.token != session.token) return;
    if (contact == null) {
      throw const ApiException(
        'Chỉ gọi điện khi đơn nhận việc đã được duyệt (ACCEPTED).',
      );
    }
    // Freeze the key so a lost response can be retried without duplicate logs.
    final key =
        'call-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => ChatCallSheet(
        api: api,
        peerName: peerName,
        job: job,
        contact: contact,
        launcher: launcher,
        logCall: () async {
          if (api.session?.token != session.token) return false;
          if (logCall != null) return logCall(key);
          await api.sendMessage(job.id, peerId, simulatedCallLog, key);
          return true;
        },
      ),
    );
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
      );
    }
  }
}

enum _CallPhase { idle, connecting, active, ended }

class ChatCallSheet extends StatefulWidget {
  const ChatCallSheet({
    super.key,
    required this.api,
    required this.job,
    required this.peerName,
    required this.contact,
    required this.logCall,
    this.launcher,
  });
  final ApiService api;
  final Job job;
  final String peerName;
  final ChatContact contact;
  final Future<bool> Function() logCall;
  final Future<bool> Function(Uri)? launcher;
  @override
  State<ChatCallSheet> createState() => _ChatCallSheetState();
}

class _ChatCallSheetState extends State<ChatCallSheet>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _waves = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final String? _sessionToken;
  _CallPhase _phase = _CallPhase.idle;
  Timer? _connecting, _ticker;
  int _elapsedSeconds = 0;
  bool _mic = true, _speaker = false, _busy = false, _logged = false;
  bool _logPending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sessionToken = widget.api.session?.token;
    widget.api.addListener(_sessionChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void _sessionChanged() {
    if (widget.api.session?.token == _sessionToken) return;
    _stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        (_phase == _CallPhase.active || _phase == _CallPhase.connecting)) {
      _stop();
      setState(() {
        _phase = _CallPhase.ended;
        _error = 'Cuộc gọi mô phỏng đã dừng khi ứng dụng vào nền.';
      });
    }
  }

  void _start() {
    _elapsedSeconds = 0;
    setState(() => _phase = _CallPhase.connecting);
    if (!MediaQuery.disableAnimationsOf(context)) _waves.repeat();
    _connecting = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _phase = _CallPhase.active);
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _elapsedSeconds = timer.tick);
      });
    });
  }

  void _stop() {
    _connecting?.cancel();
    _ticker?.cancel();
    _waves.stop();
  }

  Future<void> _end() async {
    final active = _phase == _CallPhase.active;
    _stop();
    setState(() => _phase = _CallPhase.ended);
    if (active) {
      _logPending = true;
      await _saveLog();
    }
  }

  Future<void> _saveLog() async {
    if (_busy || _logged) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    var saved = false;
    try {
      saved = await widget.logCall();
    } on Object {
      /* Retry with the same key. */
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _logged = saved;
      if (!saved) {
        _error = 'Chưa gửi được nhật ký cuộc gọi. Bạn có thể thử lại.';
      }
    });
  }

  Future<void> _sim() async {
    final phone = widget.contact.phone;
    if (phone == null || phone.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    var opened = false;
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      opened =
          await (widget.launcher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
    } on Object {
      /* A desktop may have no registered telephone handler. */
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!opened) {
        _error =
            'Thiết bị chưa có ứng dụng gọi điện. Hãy sao chép số để liên hệ.';
      }
    });
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.contact.phone!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(
            content: const Text('Đã sao chép số điện thoại'),
            kind: NoticeKind.info,
          ),
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Không sao chép được số trên thiết bị này.');
      }
    }
  }

  @override
  void dispose() {
    widget.api.removeListener(_sessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _waves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running =
        _phase == _CallPhase.active || _phase == _CallPhase.connecting;
    final phone = widget.contact.phone;
    final elapsed = _elapsedSeconds;
    final time =
        '${(elapsed ~/ 60).toString().padLeft(2, '0')}:${(elapsed % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: !running && !_busy,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Liên hệ công trình',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng gọi điện',
                      color: Colors.white,
                      onPressed: running || _busy
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _waves,
                  builder: (context, child) => Container(
                    padding: EdgeInsets.all(
                      8 + (running ? _waves.value * 10 : 0),
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF22C55E)
                            .withValues(alpha: .5 - _waves.value * .3),
                        width: 2,
                      ),
                    ),
                    child: child,
                  ),
                  child: ChatAvatar(name: widget.peerName, radius: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.peerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.job.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  switch (_phase) {
                    _CallPhase.idle => 'Chọn cách liên hệ',
                    _CallPhase.connecting => 'Đang kết nối… (mô phỏng)',
                    _CallPhase.active => 'Đang gọi · $time',
                    _CallPhase.ended => 'Đã kết thúc · $time',
                  },
                  style: const TextStyle(
                    color: Color(0xFF86EFAC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (phone != null && phone.isNotEmpty) ...[
                  SelectableText(
                    phone,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  TextButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy, size: 16),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    label: const Text('Sao chép số'),
                  ),
                ] else
                  const Text(
                    'Chưa có số điện thoại liên hệ',
                    style: TextStyle(color: Colors.white70),
                  ),
                if (_phase == _CallPhase.idle) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy || phone == null || phone.isEmpty
                          ? null
                          : _sim,
                      icon: const Icon(Icons.sim_card_outlined),
                      label: const Text('Gọi qua SIM'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _busy ? null : _start,
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Gọi trực tiếp trên App (mô phỏng)'),
                    ),
                  ),
                ],
                if (running)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        tooltip: _mic
                            ? 'Tắt mic (mô phỏng)'
                            : 'Bật mic (mô phỏng)',
                        onPressed: () => setState(() => _mic = !_mic),
                        icon: Icon(_mic ? Icons.mic : Icons.mic_off),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filled(
                        tooltip: 'Kết thúc cuộc gọi',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _end,
                        icon: const Icon(Icons.call_end),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filledTonal(
                        tooltip: _speaker
                            ? 'Tắt loa ngoài (mô phỏng)'
                            : 'Bật loa ngoài (mô phỏng)',
                        onPressed: () => setState(() => _speaker = !_speaker),
                        icon: Icon(
                          _speaker ? Icons.volume_up : Icons.volume_down,
                        ),
                      ),
                    ],
                  ),
                if (_phase == _CallPhase.ended &&
                    _logPending &&
                    !_busy &&
                    !_logged &&
                    _error != null)
                  TextButton(
                    onPressed: _saveLog,
                    child: const Text('Gửi lại nhật ký'),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                if (_logged)
                  const Text(
                    'Đã gửi nhật ký cuộc gọi vào cuộc trò chuyện',
                    style: TextStyle(color: Color(0xFF86EFAC)),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFDA4AF)),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Chế độ App chỉ mô phỏng giao diện, không truyền âm thanh hoặc gọi tới đối phương. Gọi qua SIM để liên hệ thật.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
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
