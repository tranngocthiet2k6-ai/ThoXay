import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ServerConnectionNotice extends StatelessWidget {
  const ServerConnectionNotice({super.key, required this.api});
  final ApiService api;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: api.connectionWaiting,
    builder: (context, _) {
      if (!api.warmingUp) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Đang kết nối máy chủ. Lần đầu có thể lâu hơn bình thường, vui lòng chờ…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    },
  );
}
