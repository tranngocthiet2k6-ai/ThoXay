import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/design_motion.dart';
import '../widgets/profile_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.api});
  final ApiService api;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt')),
    body: ContentFrame(
      maxWidth: 640,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: ProfileSettings(api: api),
      ),
    ),
  );
}
