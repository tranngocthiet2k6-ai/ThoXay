import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class KycPhoto {
  const KycPhoto(this.bytes);
  final Uint8List bytes;
}

class KycCamera {
  KycCamera({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  static final instance = KycCamera();
  final ImagePicker _picker;
  static const _pending = 'thoxay.kyc.pending';
  ({int userId, String face, XFile file})? _lost;

  bool get usesFileSelection =>
      !kIsWeb &&
      {
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);

  Future<void> restoreLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final prefs = await SharedPreferences.getInstance();
    final marker = prefs.getStringList(_pending);
    try {
      final data = await _picker.retrieveLostData();
      if (marker != null &&
          marker.length == 2 &&
          data.files?.isNotEmpty == true) {
        final id = int.tryParse(marker[0]);
        if (id != null && {'front', 'back'}.contains(marker[1])) {
          _lost = (userId: id, face: marker[1], file: data.files!.first);
        }
      }
    } on Object {
      // Recovery must never prevent opening the app; a new capture remains available.
    } finally {
      await prefs.remove(_pending);
    }
  }

  Future<({String face, KycPhoto photo})?> recover(int userId) async {
    final lost = _lost;
    _lost = null;
    if (lost == null || lost.userId != userId) return null;
    return (face: lost.face, photo: await _read(lost.file));
  }

  Future<KycPhoto?> capture(int userId, String face) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pending, ['$userId', face]);
    try {
      final file = await _picker.pickImage(
        source: usesFileSelection ? ImageSource.gallery : ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      return file == null ? null : await _read(file);
    } finally {
      await prefs.remove(_pending);
    }
  }

  Future<KycPhoto> _read(XFile file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const ApiException(
        'Mỗi ảnh tối đa 5 MB. Hãy chụp lại ảnh nhỏ hơn.',
      );
    }
    return KycPhoto(await file.readAsBytes());
  }
}
