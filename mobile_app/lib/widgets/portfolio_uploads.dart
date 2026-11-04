import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/portfolio_photo.dart';
import '../services/api_service.dart';
import '../services/device_photo_picker.dart';
import 'content_skeleton.dart';
import 'private_image.dart';
import 'photo_preview_dialog.dart';

class PortfolioUploads extends StatefulWidget {
  const PortfolioUploads({
    super.key,
    required this.api,
    required this.ownerId,
    this.editable = false,
    this.picker,
    this.compact = false,
  });
  final ApiService api;
  final int ownerId;
  final bool editable;
  final DevicePhotoPicker? picker;
  final bool compact;
  @override
  State<PortfolioUploads> createState() => _PortfolioUploadsState();
}

class _PortfolioUploadsState extends State<PortfolioUploads> {
  List<PortfolioPhoto> _photos = [];
  bool _loading = true, _busy = false, _choosing = false, _showAll = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final photos = await widget.api.portfolio(widget.ownerId);
      if (mounted) setState(() => _photos = photos);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(ImageSource source) async {
    if (_busy || _choosing) return;
    _choosing = true;
    try {
      final bytes = await (widget.picker ?? DevicePhotoPicker()).pick(source);
      if (bytes == null || !mounted) return;
      final caption = await showDialog<String>(
        context: context,
        builder: (_) => PhotoPreviewDialog(bytes: bytes),
      );
      if (caption == null || !mounted) return;
      setState(() => _busy = true);
      await widget.api.uploadPortfolio(bytes, caption);
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Không mở được camera/thư viện ảnh. Hãy cấp quyền và thử lại.',
        );
      }
    } finally {
      _choosing = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(PortfolioPhoto photo) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh tay nghề?'),
        content: const Text('Ảnh sẽ được gỡ khỏi hồ sơ của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa ảnh'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.deletePortfolio(photo.id);
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Tay nghề & công trình',
            style: widget.compact
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.editable)
            PopupMenuButton<ImageSource>(
              enabled: !_busy && !_loading && _photos.length < 12,
              onSelected: _add,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: ImageSource.camera,
                  child: Text('Chụp ảnh công trình'),
                ),
                PopupMenuItem(
                  value: ImageSource.gallery,
                  child: Text('Chọn từ thư viện'),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined),
                    SizedBox(width: 8),
                    Text('Thêm ảnh'),
                  ],
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (_loading) const ContentSkeleton(compact: true),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) ...[
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton(
          onPressed: _busy ? null : _load,
          child: const Text('Tải lại bộ ảnh'),
        ),
      ],
      if (!_loading && _photos.isEmpty && _error == null)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Chưa có ảnh tay nghề. Chụp hoặc chọn ảnh công trình bạn đã thực hiện để giới thiệu kinh nghiệm.',
          ),
        ),
      if (!_loading)
        LayoutBuilder(
          builder: (context, bounds) => Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              for (final photo in (_showAll ? _photos : _photos.take(3)))
                SizedBox(
                  width: (bounds.maxWidth - 24) / 3,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: () => showPrivatePhoto(
                            context,
                            widget.api,
                            photo.path,
                            photo.caption,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                PrivateImage(api: widget.api, path: photo.path),
                                if (photo.caption.isNotEmpty)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: ColoredBox(
                                      color: const Color(0xdd0f172a),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          photo.caption,
                                          maxLines: widget.compact ? 1 : 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (widget.editable)
                          TextButton.icon(
                            onPressed: _busy ? null : () => _delete(photo),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Xóa ảnh'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      if (!widget.compact && !_showAll && _photos.length > 3)
        TextButton(
          onPressed: () => setState(() => _showAll = true),
          child: Text('Xem tất cả ${_photos.length} ảnh công trình'),
        ),
    ],
  );
}
