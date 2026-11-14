import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import 'commercial_hero.dart';

class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.api,
    required this.name,
    this.path,
    this.size = 64,
    this.online,
  });
  final ApiService api;
  final String name;
  final String? path;
  final double size;
  final bool? online;
  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  Future<Uint8List>? _photo;
  void _load() {
    _photo = widget.path == null ? null : widget.api.privateImage(widget.path!);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path || widget.api != oldWidget.api) _load();
  }

  Widget get _fallback => PresenceAvatar(
    name: widget.name,
    size: widget.size,
    online: widget.online,
  );
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ảnh đại diện ${widget.name}',
    image: true,
    child: SizedBox.square(
      dimension: widget.size,
      child: _photo == null
          ? _fallback
          : FutureBuilder<Uint8List>(
              future: _photo,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return _fallback;
                return Stack(
                  children: [
                    ClipOval(
                      child: Image.memory(
                        snapshot.data!,
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => _fallback,
                      ),
                    ),
                    if (widget.online != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.online!
                                ? const Color(0xff34d399)
                                : const Color(0xff94a3b8),
                            border: Border.all(
                              color: const Color(0xff0f172a),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    ),
  );
}
