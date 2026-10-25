class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.jobId,
    required this.content,
    required this.createdAt,
    required this.clientMessageId,
  });
  final int id, senderId, recipientId, jobId;
  final String content, clientMessageId;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] as num).toInt(),
    senderId: (json['senderId'] as num).toInt(),
    recipientId: (json['recipientId'] as num).toInt(),
    jobId: (json['jobId'] as num).toInt(),
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    clientMessageId: json['clientMessageId'] as String,
  );
}

class MessagePage {
  const MessagePage(this.messages, this.hasMore);
  final List<ChatMessage> messages;
  final bool hasMore;
}
