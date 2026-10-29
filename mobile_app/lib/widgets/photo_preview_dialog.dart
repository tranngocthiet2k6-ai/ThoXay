import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PhotoPreviewDialog extends StatefulWidget {
  const PhotoPreviewDialog({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<PhotoPreviewDialog> createState() => _PhotoPreviewDialogState();
}

class _PhotoPreviewDialogState extends State<PhotoPreviewDialog> {
  final _caption = TextEditingController();
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Xem trước ảnh dự án'),
    scrollable: true,
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 240,
            child: InteractiveViewer(
              maxScale: 5,
              child: Image.memory(widget.bytes, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            maxLength: 160,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Chú thích ảnh (không bắt buộc)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Chọn lại sau'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.pop(context, _caption.text.trim()),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Tải ảnh lên'),
      ),
    ],
  );
}
