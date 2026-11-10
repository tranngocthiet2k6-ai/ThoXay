import 'bouncing_button.dart';

import 'package:flutter/material.dart';

/// One primary application action; chat remains governed by ACCEPTED status.
class JobApplicationActions extends StatelessWidget {
  const JobApplicationActions({
    super.key,
    required this.onApply,
    required this.onNegotiate,
    required this.onChat,
    this.applied = false,
    this.busy = false,
  });
  final VoidCallback? onApply, onNegotiate, onChat;
  final bool applied, busy;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Tooltip(
        message: onChat == null
            ? 'Nhắn tin sau khi đơn được duyệt'
            : 'Nhắn tin',
        child: IconButton.outlined(
          key: const ValueKey('job-detail-chat'),
          onPressed: onChat,
          icon: const Icon(Icons.chat_bubble_outline, size: 20),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(fontSize: 12),
          ),
          onPressed: applied || busy ? null : onNegotiate,
          child: const Text('Thương lượng giá', textAlign: TextAlign.center),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: BouncingButton(
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: applied || busy ? null : onApply,
            child: Text(
              applied ? 'Đã ứng tuyển' : 'Ứng tuyển ngay',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ],
  );
}
