import 'package:flutter/material.dart';

Future<String?> showCancelWorkDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _CancelWorkDialog(),
    );

class _CancelWorkDialog extends StatefulWidget {
  const _CancelWorkDialog();
  @override
  State<_CancelWorkDialog> createState() => _CancelWorkDialogState();
}

class _CancelWorkDialogState extends State<_CancelWorkDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Hủy việc đang làm?'),
    scrollable: true,
    content: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Thao tác này trừ 15 điểm uy tín (tối thiểu 0), tính lại bậc thợ và thông báo chủ thầu. Bạn sẽ mất quyền nhắn tin và liên hệ qua đơn này. Đơn đã hủy không thể khôi phục.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('cancellation-reason'),
            controller: _reason,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Lý do hủy việc'),
            validator: (v) => (v?.trim().isEmpty ?? true)
                ? 'Vui lòng nhập lý do hủy việc'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tiếp tục làm việc'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _reason.text.trim());
          }
        },
        child: const Text('Xác nhận hủy việc'),
      ),
    ],
  );
}
