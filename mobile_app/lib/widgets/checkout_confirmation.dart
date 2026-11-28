import 'package:flutter/material.dart';

Future<bool> confirmCheckout(BuildContext context, DateTime checkedInAt) async {
  final vn = checkedInAt.toUtc().add(const Duration(hours: 7));
  final time =
      '${vn.hour.toString().padLeft(2, '0')}:${vn.minute.toString().padLeft(2, '0')}';
  final recent = DateTime.now().toUtc().difference(checkedInAt.toUtc());
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bạn muốn kết thúc ca làm?'),
          content: Text(
            'Bạn vào ca lúc $time (giờ Việt Nam). Giờ ra được ghi nhận khi bạn xác nhận.'
            '${!recent.isNegative && recent.inMinutes < 5 ? '\n\nBạn vừa bắt đầu ca, hãy kiểm tra lại.' : ''}',
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tiếp tục làm'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận kết thúc ca'),
            ),
          ],
        ),
      ) ??
      false;
}
