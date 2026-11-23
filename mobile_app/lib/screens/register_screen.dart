import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'auth_screen.dart';

/// Compatibility entry point; tab changes stay inside the shared AuthScreen.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, required this.api});
  final ApiService api;
  @override
  Widget build(BuildContext context) => AuthScreen(api: api, initialTab: 1);
}
