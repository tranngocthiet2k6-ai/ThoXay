import 'app_snack_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CallButton extends StatelessWidget {
  const CallButton({
    super.key,
    required this.phone,
    required this.label,
    this.launcher,
  });
  final String phone, label;
  final Future<bool> Function(Uri)? launcher;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: phone);
    var opened = false;
    try {
      opened =
          await (launcher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
    } on PlatformException {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          kind: NoticeKind.error,
          content: Text(
            'Thiết bị chưa có ứng dụng gọi điện. Số liên hệ: $phone',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => _call(context),
    icon: const Icon(Icons.call_outlined),
    label: Text('$label: $phone'),
  );
}
