import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class DevicePhotoPicker {
  DevicePhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  Future<Uint8List?> pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    if (await file.length() > 5 * 1024 * 1024) {
      throw const ApiException('Mỗi ảnh tối đa 5 MB');
    }
    return file.readAsBytes();
  }
}
