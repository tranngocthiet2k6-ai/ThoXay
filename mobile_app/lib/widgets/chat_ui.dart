import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'private_image.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.connected,
    this.statusLabel = 'Trạng thái hoạt động chưa được cung cấp',
  });
  final String name, statusLabel;
  final double radius;
  final bool? connected;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Text(
          name.trim().isEmpty
              ? '?'
              : name.trim().characters.first.toUpperCase(),
          style: TextStyle(fontSize: radius * .75, fontWeight: FontWeight.w800),
        ),
      ),
      if (radius >= 20)
        Positioned(
          right: 0,
          bottom: 0,
          child: Tooltip(
            message: statusLabel,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connected == true
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF94A3B8),
                border: Border.all(
                  color: AppPalette.of(context).surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

String chatTime(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String chatDay(DateTime value, {DateTime? now}) {
  final day = value.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final date = DateTime(day.year, day.month, day.day);
  final start = DateTime(today.year, today.month, today.day);
  if (date == start) return 'Hôm nay';
  if (date == DateTime(today.year, today.month, today.day - 1)) {
    return 'Hôm qua';
  }
  return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
}

class ChatDayDivider extends StatelessWidget {
  const ChatDayDivider({super.key, required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            chatDay(date),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    ),
  );
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.api,
    required this.message,
    required this.mine,
    required this.peerName,
    required this.onLocation,
    this.peerLastReadMessageId,
  });
  final ApiService api;
  final ChatMessage message;
  final bool mine;
  final String peerName;
  final int? peerLastReadMessageId;
  final void Function(double, double) onLocation;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final foreground = mine ? Colors.white : palette.ink;
    final accent = api.session?.role == 'ROLE_CONTRACTOR'
        ? const Color(0xFF059669)
        : const Color(0xFFEA580C);
    final seen =
        peerLastReadMessageId != null && message.id <= peerLastReadMessageId!;
    return LayoutBuilder(
      builder: (context, bounds) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: mine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) ...[
              ChatAvatar(name: peerName, radius: 14),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                key: ValueKey('message-${message.id}'),
                constraints: BoxConstraints(
                  maxWidth: (bounds.maxWidth * .8).clamp(0, 480),
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mine ? accent : palette.surface,
                  border: mine ? null : Border.all(color: palette.border),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(mine ? 20 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.kind == 'IMAGE' &&
                        message.imagePath != null) ...[
                      Semantics(
                        label: 'Phóng to ảnh công trường',
                        button: true,
                        child: InkWell(
                          onTap: () => showPrivatePhoto(
                            context,
                            api,
                            message.imagePath!,
                            message.content,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 260,
                              height: 180,
                              child: PrivateImage(
                                api: api,
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
                        message.longitude != null) ...[
                      Icon(Icons.location_on, size: 32, color: foreground),
                      Text(
                        '${message.latitude!.toStringAsFixed(5)}, ${message.longitude!.toStringAsFixed(5)}',
                        style: TextStyle(color: foreground, fontSize: 12),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: foreground,
                          side: BorderSide(
                            color: foreground.withValues(alpha: .4),
                          ),
                        ),
                        onPressed: () =>
                            onLocation(message.latitude!, message.longitude!),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Mở vị trí trên bản đồ'),
                      ),
                    ],
                    if (message.content.isNotEmpty)
                      Text(
                        message.content,
                        style: TextStyle(color: foreground, height: 1.5),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${chatTime(message.createdAt)}${mine ? ' · ${seen ? 'Đã xem' : 'Đã gửi'}' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: mine ? Colors.white70 : palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
