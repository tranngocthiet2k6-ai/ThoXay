import 'bouncing_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/device_photo_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class WorkPhotoDraft {
  const WorkPhotoDraft(this.overview, this.detail, this.caption);
  final Uint8List overview, detail;
  final String caption;
}

class WorkPhotoReportDialog extends StatefulWidget {
  const WorkPhotoReportDialog({super.key, required this.picker});
  final DevicePhotoPicker picker;
  @override
  State<WorkPhotoReportDialog> createState() => _WorkPhotoReportDialogState();
}

class _WorkPhotoReportDialogState extends State<WorkPhotoReportDialog> {
  final _photos = <Uint8List?>[null, null];
  final _caption = TextEditingController();
  bool _choosing = false;
  String? _error;
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(int index, ImageSource source) async {
    if (_choosing) return;
    setState(() => _choosing = true);
    try {
      final photo = await widget.picker.pick(source);
      if (mounted && photo != null) setState(() => _photos[index] = photo);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _error = 'Chưa truy cập được camera hoặc thư viện. Hãy kiểm tra quyền và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  void _zoom(Uint8List bytes) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Kiểm tra ảnh công việc')),
        body: InteractiveViewer(
          maxScale: 5,
          child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_choosing,
    child: AlertDialog(
      title: const Text('Báo cáo tiến độ cuối ngày'),
      scrollable: true,
      content: SizedBox(
        width: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thêm 2 ảnh công việc đã hoàn thành · ${_photos.whereType<Uint8List>().length}/2 ảnh',
              style: TextStyle(
                color: AppPalette.of(context).muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 2; i++) ...[
                  if (i == 1) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 140,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppPalette.of(context).soft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppPalette.of(context).border,
                            ),
                          ),
                          child: _photos[i] == null
                              ? Center(
                                  child: Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 30,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                )
                              : InkWell(
                                  onTap: () => _zoom(_photos[i]!),
                                  child: Image.memory(
                                    _photos[i]!,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        Text(
                          i == 0 ? 'Trước · Toàn cảnh' : 'Sau · Chi tiết',
                          style: const TextStyle(fontSize: 11),
                        ),
                        PopupMenuButton<ImageSource>(
                          tooltip: i == 0
                              ? 'Chọn ảnh toàn cảnh'
                              : 'Chọn ảnh chi tiết',
                          enabled: !_choosing,
                          onSelected: (source) => _pick(i, source),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: ImageSource.camera,
                              child: Text('Chụp bằng camera'),
                            ),
                            PopupMenuItem(
                              value: ImageSource.gallery,
                              child: Text('Chọn từ thư viện'),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _photos[i] == null ? '+ Thêm ảnh' : 'Đổi ảnh',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              enabled: !_choosing,
              maxLength: 1000,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mô tả kết quả công việc',
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_choosing) const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _choosing ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        BouncingButton(
          child: FilledButton(
            onPressed: _choosing || _photos.any((p) => p == null)
                ? null
                : () => Navigator.pop(
                    context,
                    WorkPhotoDraft(
                      _photos[0]!,
                      _photos[1]!,
                      _caption.text.trim(),
                    ),
                  ),
            child: const Text('Gửi báo cáo'),
          ),
        ),
      ],
    ),
  );
}
