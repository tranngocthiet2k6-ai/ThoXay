import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'api_service.dart';
import 'chat_connection.dart';

enum ChatStatus { connecting, connected, reconnecting, stopped }

class ChatController extends ChangeNotifier {
  ChatController(this.api, this.jobId, this.peerId)
    : userId = api.session!.userId,
      _token = api.session!.token {
    api.addListener(_sessionChanged);
  }
  final ApiService api;
  final int jobId, peerId, userId;
  final String _token;
  final _messages = <int, ChatMessage>{};
  List<ChatMessage> get messages =>
      _messages.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  ChatStatus status = ChatStatus.connecting;
  bool loading = true, sending = false, loadingOlder = false, hasOlder = false;
  String? error;
  bool _disposed = false, _initialized = false;
  int _generation = 0, _attempt = 0, _syncCursor = 0;
  ChatConnection? _connection;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _retry, _heartbeat;
  String? _pendingId, _pendingText;
  bool get canSend => status == ChatStatus.connected && !sending && !_disposed;

  void start() => unawaited(_connect());
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  Future<void> _connect() async {
    if (_disposed || status == ChatStatus.stopped) return;
    _retry?.cancel();
    final generation = ++_generation;
    final baseline = _syncCursor;
    status = _attempt == 0 ? ChatStatus.connecting : ChatStatus.reconnecting;
    _notify();
    try {
      final connection = await api.connectChat(jobId, peerId);
      if (!_current(generation)) {
        await connection.close();
        return;
      }
      _connection = connection;
      _subscription = connection.events.listen(
        (event) {
          if (!_current(generation)) return;
          _armHeartbeat(generation);
          switch (event['type']) {
            case 'ready':
              unawaited(_synchronize(generation, baseline));
            case 'message':
              try {
                _merge([
                  ChatMessage.fromJson(
                    event['message'] as Map<String, dynamic>,
                  ),
                ]);
              } on Object {
                _lost(generation);
              }
            case 'error':
              _stop(
                event['message'] as String? ??
                    'Không thể truy cập cuộc trò chuyện',
              );
              if (event['code'] == 'UNAUTHORIZED' ||
                  event['code'] == 'ACCOUNT_LOCKED') {
                unawaited(api.logout());
              }
          }
        },
        onError: (Object _) => _lost(generation),
        onDone: () => _lost(generation),
      );
      _armHeartbeat(generation);
    } on ApiException catch (e) {
      if (!_current(generation)) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        _stop(e.message);
      } else {
        _lost(generation);
      }
    } on Object {
      _lost(generation);
    }
  }

  void _merge(Iterable<ChatMessage> incoming) {
    for (final message in incoming) {
      if (message.jobId == jobId &&
          ((message.senderId == userId && message.recipientId == peerId) ||
              (message.senderId == peerId && message.recipientId == userId))) {
        _messages[message.id] = message;
      }
    }
    _notify();
  }

  Future<void> _synchronize(int generation, int baseline) async {
    try {
      int? after = _initialized ? baseline : null;
      while (_current(generation)) {
        final page = await api.messageHistory(jobId, peerId, afterId: after);
        if (!_current(generation)) return;
        _merge(page.messages);
        if (page.messages.isNotEmpty) _syncCursor = page.messages.last.id;
        if (after == null) {
          hasOlder = page.hasMore;
          break;
        }
        if (!page.hasMore || page.messages.isEmpty) break;
        after = page.messages.last.id;
      }
      if (!_current(generation)) return;
      _initialized = true;
      loading = false;
      error = null;
      _attempt = 0;
      status = ChatStatus.connected;
      _notify();
    } on ApiException catch (e) {
      if (!_current(generation)) return;
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
        _stop(e.message);
      } else {
        _lost(generation);
      }
    } on Object {
      _lost(generation);
    }
  }

  void _armHeartbeat(int generation) {
    _heartbeat?.cancel();
    _heartbeat = Timer(const Duration(seconds: 30), () => _lost(generation));
  }

  void _disconnect() {
    _heartbeat?.cancel();
    final subscription = _subscription;
    _subscription = null;
    final connection = _connection;
    _connection = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (connection != null) {
      unawaited(connection.close().catchError((Object _) {}));
    }
  }

  void _lost(int generation) {
    if (!_current(generation) || status == ChatStatus.stopped) return;
    ++_generation;
    _disconnect();
    loading = false;
    status = ChatStatus.reconnecting;
    error = 'Mất kết nối. Đang kết nối lại và đồng bộ tin nhắn…';
    final delay = min(15, 1 << min(_attempt++, 4));
    _retry?.cancel();
    _retry = Timer(Duration(seconds: delay), _connect);
    _notify();
  }

  void _stop(String message) {
    ++_generation;
    _retry?.cancel();
    _disconnect();
    status = ChatStatus.stopped;
    loading = false;
    error = message;
    _notify();
  }

  void reconnect() {
    if (_disposed || status == ChatStatus.stopped) return;
    ++_generation;
    _disconnect();
    _attempt = 0;
    unawaited(_connect());
  }

  Future<void> loadOlder() async {
    if (loadingOlder ||
        !hasOlder ||
        messages.isEmpty ||
        status != ChatStatus.connected) {
      return;
    }
    loadingOlder = true;
    _notify();
    try {
      final page = await api.messageHistory(
        jobId,
        peerId,
        beforeId: messages.first.id,
      );
      if (_disposed) return;
      hasOlder = page.hasMore;
      _merge(page.messages);
    } on ApiException catch (e) {
      if (!_disposed) {
        if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
          _stop(e.message);
        } else {
          error = 'Không tải được tin cũ. Hãy thử lại.';
        }
      }
    } on Object {
      if (!_disposed) error = 'Không tải được tin cũ. Hãy thử lại.';
    } finally {
      loadingOlder = false;
      _notify();
    }
  }

  Future<bool> send(String draft) async {
    final content = draft.trim();
    if (!canSend || content.isEmpty || content.length > 2000) return false;
    if (_pendingText != content) {
      _pendingText = content;
      final random = Random.secure();
      _pendingId = base64UrlEncode(
        List<int>.generate(18, (_) => random.nextInt(256)),
      );
    }
    final sent = await sendMedia(
      () => api.sendMessage(jobId, peerId, content, _pendingId!),
    );
    if (sent) {
      _pendingId = null;
      _pendingText = null;
    }
    return sent;
  }

  /// The composer owns the frozen media payload and idempotency key across retries.
  Future<bool> sendMedia(Future<ChatMessage> Function() request) async {
    if (!canSend) return false;
    sending = true;
    error = null;
    _notify();
    try {
      final message = await request();
      if (_disposed) return false;
      _merge([message]);
      return true;
    } on ApiException catch (e) {
      if (!_disposed) {
        if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
          _stop(e.message);
        } else {
          error = '${e.message}. Nội dung vẫn được giữ để gửi lại.';
        }
      }
      return false;
    } on Object {
      if (!_disposed) error = 'Chưa xác nhận được tin nhắn. Hãy bấm gửi lại.';
      return false;
    } finally {
      sending = false;
      _notify();
    }
  }

  void _sessionChanged() {
    if (api.session?.token != _token || api.session?.userId != userId) {
      _stop('Phiên đăng nhập đã kết thúc');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _retry?.cancel();
    _disconnect();
    api.removeListener(_sessionChanged);
    super.dispose();
  }
}
