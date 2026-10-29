import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PhotoPreviewDialog extends StatefulWidget {
  const PhotoPreviewDialog({
    super.key,
    required this.bytes,
    this.title = 'Xem trước ảnh dự án',
    this.maxCaption = 160,
  });
  final Uint8List bytes;
  final String title;
  final int maxCaption;
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
    title: Text(widget.title),
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
            maxLength: widget.maxCaption,
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
