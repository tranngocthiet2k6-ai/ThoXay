import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import 'loading_jobs.dart';

class PrivateImage extends StatefulWidget {
  const PrivateImage({
    super.key,
    required this.api,
    required this.path,
    this.fit = BoxFit.cover,
  });
  final ApiService api;
  final String path;
  final BoxFit fit;
  @override
  State<PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<PrivateImage> {
  late Future<Uint8List> _image;
  Widget _retry() => ColoredBox(
    color: const Color(0xffe2e8f0),
    child: Center(
      child: TextButton.icon(
        onPressed: () {
          final next = widget.api.privateImage(widget.path);
          setState(() {
            _image = next;
          });
        },
        icon: const Icon(Icons.broken_image_outlined),
        label: const Text('Tải lại ảnh', style: TextStyle(fontSize: 10)),
      ),
    ),
  );
  @override
  void initState() {
    super.initState();
    _image = widget.api.privateImage(widget.path);
  }

  @override
  void didUpdateWidget(covariant PrivateImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.api != widget.api) {
      _image = widget.api.privateImage(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _image,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _retry();
      }
      if (!snapshot.hasData) {
        return const ShimmerSurface(child: SkeletonLine(height: 120));
      }
      return Image.memory(
        snapshot.data!,
        fit: widget.fit,
        errorBuilder: (_, e, s) => _retry(),
      );
    },
  );
}

Future<void> showPrivatePhoto(
  BuildContext context,
  ApiService api,
  String path,
  String caption,
) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    child: SizedBox(
      width: 900,
      height: MediaQuery.sizeOf(context).height * .8,
      child: Column(
        children: [
          ListTile(
            title: Text(caption.isEmpty ? 'Ảnh công trình' : caption),
            trailing: IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: 'Đóng ảnh',
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: .5,
              maxScale: 5,
              child: PrivateImage(api: api, path: path, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    ),
  ),
);
