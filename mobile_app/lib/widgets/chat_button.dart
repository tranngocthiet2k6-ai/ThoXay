import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/chat_screen.dart';
import '../services/api_service.dart';

class ChatButton extends StatelessWidget {
  const ChatButton({
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
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatScreen(api: api, job: job, peerId: peerId, peerName: peerName),
      ),
    ),
    icon: const Icon(Icons.chat_bubble_outline),
    label: const Text('Nhắn tin'),
  );
}
