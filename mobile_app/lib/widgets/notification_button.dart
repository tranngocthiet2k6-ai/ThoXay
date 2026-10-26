import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../screens/notifications_screen.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key, required this.api});
  final ApiService api;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Thông báo',
    icon: const Icon(Icons.notifications_none),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NotificationsScreen(api: api)),
    ),
  );
}
