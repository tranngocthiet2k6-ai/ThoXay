class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.jobId,
  });
  final int id;
  final int? jobId;
  final String type, title, body;
  final DateTime createdAt;
  final DateTime? readAt;
  bool get isRead => readAt != null;
  AppNotification markRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    readAt: readAt ?? DateTime.now().toUtc(),
    jobId: jobId,
  );
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        jobId: (json['jobId'] as num?)?.toInt(),
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
      );
}

class NotificationPage {
  const NotificationPage(this.items, this.hasMore, this.unreadCount);
  final List<AppNotification> items;
  final bool hasMore;
  final int unreadCount;
}
