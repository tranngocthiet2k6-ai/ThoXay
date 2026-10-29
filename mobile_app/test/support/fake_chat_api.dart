import 'dart:async';

import 'package:tho_xay_mobile/models/chat_message.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/chat_connection.dart';

ChatMessage message(
  int id, {
  String? content,
  int sender = 2,
  String? clientId,
}) => ChatMessage(
  id: id,
  senderId: sender,
  recipientId: sender == 2 ? 3 : 2,
  jobId: 1,
  content: content ?? 'Tin $id',
  createdAt: DateTime.utc(2026, 10, 26, 8),
  clientMessageId: clientId ?? 'id-$id',
);
Map<String, dynamic> messageEvent(ChatMessage m) => {
  'type': 'message',
  'message': {
    'id': m.id,
    'senderId': m.senderId,
    'recipientId': m.recipientId,
    'jobId': m.jobId,
    'content': m.content,
    'createdAt': m.createdAt.toIso8601String(),
    'clientMessageId': m.clientMessageId,
    'kind': m.kind,
    'imagePath': m.imagePath,
    'latitude': m.latitude,
    'longitude': m.longitude,
  },
};
const chatJob = Job(
  id: 1,
  contractorId: 2,
  contractorName: 'Chủ thầu A',
  contractorPhone: '0900000002',
  title: 'Công trình A',
  description: '',
  jobType: 'Thợ chính',
  salaryPerDay: 500000,
  address: 'TP.HCM',
  latitude: 10,
  longitude: 106,
  requiredWorkers: 1,
  status: 'IN_PROGRESS',
);

class FakeChatApi extends ApiService {
  bool loggedOut = false, failSendOnce = false;
  int closed = 0;
  final rows = <ChatMessage>[];
  final connections = <StreamController<Map<String, dynamic>>>[];
  final sentIds = <String>[];
  final historyQueries = <({int? after, int? before})>[];
  Completer<MessagePage>? initialHistory;
  @override
  AuthSession? get session => loggedOut
      ? null
      : AuthSession(
          token: 'test-jwt',
          userId: 3,
          fullName: 'Thợ A',
          phoneNumber: '0900000003',
          role: 'ROLE_WORKER',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
  @override
  Future<void> logout() async {
    loggedOut = true;
    notifyListeners();
  }

  @override
  Future<ChatConnection> connectChat(int jobId, int peerId) async {
    final events = StreamController<Map<String, dynamic>>();
    connections.add(events);
    events.add({'type': 'ready'});
    return ChatConnection(
      events: events.stream,
      close: () async {
        closed++;
        await events.close();
      },
    );
  }

  @override
  Future<MessagePage> messageHistory(
    int jobId,
    int peerId, {
    int? afterId,
    int? beforeId,
  }) async {
    historyQueries.add((after: afterId, before: beforeId));
    if (initialHistory != null && afterId == null && beforeId == null) {
      return initialHistory!.future;
    }
    var filtered =
        rows
            .where(
              (m) =>
                  (afterId == null || m.id > afterId) &&
                  (beforeId == null || m.id < beforeId),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final more = filtered.length > 2;
    if (filtered.length > 2) {
      filtered = afterId != null
          ? filtered.take(2).toList()
          : filtered.sublist(filtered.length - 2);
    }
    return MessagePage(filtered, more);
  }

  @override
  Future<ChatMessage> sendMessage(
    int jobId,
    int recipientId,
    String content,
    String clientMessageId,
  ) async {
    sentIds.add(clientMessageId);
    final existing = rows
        .where((m) => m.clientMessageId == clientMessageId)
        .firstOrNull;
    final result =
        existing ??
        message(
          rows.isEmpty ? 1 : rows.last.id + 1,
          content: content,
          sender: 3,
          clientId: clientMessageId,
        );
    if (existing == null) {
      rows.add(result);
      connections.last.add(messageEvent(result));
    }
    if (failSendOnce) {
      failSendOnce = false;
      throw const ApiException('Mất phản hồi');
    }
    return result;
  }
}
