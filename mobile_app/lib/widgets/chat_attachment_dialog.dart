import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/chat_controller.dart';
import '../services/device_photo_picker.dart';
import '../services/location_service.dart';

/// No image/GPS is transmitted until the user explicitly confirms the preview.
class ChatAttachmentDialog extends StatefulWidget {
  const ChatAttachmentDialog({
    super.key,
    required this.chat,
    this.source,
    this.picker,
    this.location,
  });
  final ChatController chat;
  final ImageSource? source;
  final DevicePhotoPicker? picker;
  final LocationService? location;
  @override
  State<ChatAttachmentDialog> createState() => _ChatAttachmentDialogState();
}

class _ChatAttachmentDialogState extends State<ChatAttachmentDialog> {
  final _caption = TextEditingController();
  late final String _key = base64UrlEncode(
    List.generate(18, (_) => Random.secure().nextInt(256)),
  );
  Uint8List? _bytes;
  GeoPoint? _point;
  bool _loading = true, _sending = false, _attempted = false;
  String? _error;
  bool get _photo => widget.source != null;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_photo) {
        final bytes = await (widget.picker ?? DevicePhotoPicker()).pick(
          widget.source!,
        );
        if (!mounted) return;
        if (bytes == null) {
          Navigator.pop(context);
          return;
        }
        _bytes = bytes;
      } else {
        final point = await (widget.location ?? LocationService())
            .currentPosition();
        if (!mounted) return;
        _point = point;
      }
    } on LocationFailure catch (e) {
      if (mounted) _error = e.message;
    } on ApiException catch (e) {
      if (mounted) _error = e.message;
    } catch (_) {
      if (mounted) {
        _error = 'Không mở được camera/thư viện. Hãy cấp quyền và thử lại.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_sending || _loading) return;
    setState(() {
      _sending = true;
      _attempted = true;
      _error = null;
    });
    final chat = widget.chat;
    final ok = await chat.sendMedia(
      () => _photo
          ? chat.api.sendChatPhoto(
              chat.jobId,
              chat.peerId,
              _bytes!,
              _caption.text.trim(),
              _key,
            )
          : chat.api.sendChatLocation(
              chat.jobId,
              chat.peerId,
              _point!.latitude,
              _point!.longitude,
              _key,
            ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _sending = false;
      _error = chat.error ?? 'Chưa gửi được. Hãy kết nối lại rồi thử lại.';
    });
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: AlertDialog(
      title: Text(_photo ? 'Gửi ảnh công trường' : 'Chia sẻ vị trí GPS'),
      scrollable: true,
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            if (_bytes != null) ...[
              SizedBox(
                height: 220,
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.memory(_bytes!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _caption,
                enabled: !_attempted,
                maxLength: 2000,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Chú thích ảnh'),
              ),
            ],
            if (_point != null) ...[
              const Icon(Icons.location_on, size: 56),
              const SizedBox(height: 16),
              Text(
                '${_point!.latitude.toStringAsFixed(6)}, ${_point!.longitude.toStringAsFixed(6)}',
              ),
              const SizedBox(height: 8),
              const Text(
                'Vị trí này chỉ gửi cho người trong cuộc trò chuyện sau khi bạn xác nhận.',
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (!_loading && _bytes == null && _point == null)
          FilledButton(onPressed: _prepare, child: const Text('Thử lại'))
        else
          FilledButton.icon(
            onPressed:
                !_loading && !_sending && (_bytes != null || _point != null)
                ? _send
                : null,
            icon: const Icon(Icons.send),
            label: Text(
              _sending
                  ? 'Đang gửi…'
                  : _attempted
                  ? 'Gửi lại'
                  : 'Xác nhận gửi',
            ),
          ),
      ],
    ),
  );
}
