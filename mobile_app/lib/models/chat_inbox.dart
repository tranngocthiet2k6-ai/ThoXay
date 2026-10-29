import 'models.dart';
import 'chat_message.dart';

class ChatConversation {
  const ChatConversation({
    required this.job,
    required this.peerId,
    required this.peerName,
    required this.latest,
    required this.unreadCount,
  });
  final Job job;
  final int peerId, unreadCount;
  final String peerName;
  final ChatMessage latest;
  String get key => '${job.id}:$peerId';
  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        job: Job.fromJson(json['job'] as Map<String, dynamic>),
        peerId: (json['peerId'] as num).toInt(),
        peerName: json['peerName'] as String,
        latest: ChatMessage.fromJson(json['latest'] as Map<String, dynamic>),
        unreadCount: (json['unreadCount'] as num).toInt(),
      );
}

class ChatInbox {
  const ChatInbox(this.conversations, this.hasMore, this.unreadCount);
  final List<ChatConversation> conversations;
  final bool hasMore;
  final int unreadCount;
  factory ChatInbox.fromJson(Map<String, dynamic> json) => ChatInbox(
    (json['conversations'] as List)
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList(),
    json['hasMore'] as bool,
    (json['unreadCount'] as num).toInt(),
  );
}
