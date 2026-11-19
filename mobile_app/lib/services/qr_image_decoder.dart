import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:zxing2/qrcode.dart';

/// Local image decoding also works on Web, where MobileScanner.analyzeImage
/// is unavailable. No photo or QR payload is uploaded to a third party.
Future<String?> decodeQrImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 1200,
    allowUpscaling: false,
  );
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) {
        return null;
      }
      final pixels = Int32List(image.width * image.height);
      for (var i = 0; i < pixels.length; i++) {
        final offset = i * 4;
        pixels[i] =
            (rgba.getUint8(offset) << 16) |
            (rgba.getUint8(offset + 1) << 8) |
            rgba.getUint8(offset + 2);
      }
      final source = RGBLuminanceSource(image.width, image.height, pixels);
      final reader = QRCodeReader();
      try {
        return reader.decode(BinaryBitmap(HybridBinarizer(source))).text;
      } on ReaderException {
        return null;
      }
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
