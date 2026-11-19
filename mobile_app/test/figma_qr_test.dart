import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tho_xay_mobile/services/qr_image_decoder.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/widgets/qr_gps_status.dart';
import 'package:tho_xay_mobile/widgets/qr_scan_surface.dart';

class _Location extends LocationService {
  bool fail = false;
  @override
  Future<GeoPoint> currentPosition() async {
    if (fail) {
      throw const LocationFailure('GPS bị từ chối');
    }
    return const GeoPoint(16.4, 107.6);
  }
}

void main() {
  testWidgets(
    'gallery decodes actual QR PNG locally and ignores an image without QR',
    (tester) async {
      await tester.runAsync(() async {
        const payload = '{"type":"THOXAY_WORKER","workerId":3}';
        final painter = QrPainter(
          data: payload,
          version: QrVersions.auto,
          gapless: true,
          eyeStyle: const QrEyeStyle(color: Colors.black),
          dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
        );
        // A quiet zone around a real rendered QR, matching a photo from the gallery.
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(Colors.white, BlendMode.src);
        canvas.translate(24, 24);
        painter.paint(canvas, const Size(256, 256));
        final picture = recorder.endRecording();
        final image = await picture.toImage(304, 304);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(await decodeQrImage(data!.buffer.asUint8List()), payload);
        image.dispose();
        picture.dispose();
        final blankRecorder = ui.PictureRecorder();
        Canvas(blankRecorder).drawColor(Colors.white, BlendMode.src);
        final blankPicture = blankRecorder.endRecording();
        final blankImage = await blankPicture.toImage(200, 200);
        final blank = await blankImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        expect(await decodeQrImage(Uint8List.view(blank!.buffer)), isNull);
        blankImage.dispose();
        blankPicture.dispose();
      });
    },
  );
  testWidgets('GPS card never claims readiness before a successful position', (
    tester,
  ) async {
    final location = _Location();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QrGpsStatus(location: location)),
      ),
    );
    expect(find.text('GPS đã bật · Sẵn sàng điểm danh'), findsNothing);
    await tester.tap(find.text('Bật GPS để sẵn sàng điểm danh'));
    await tester.pumpAndSettle();
    expect(find.text('GPS đã bật · Sẵn sàng điểm danh'), findsOneWidget);
    location.fail = true;
    await tester.tap(find.text('GPS đã bật · Sẵn sàng điểm danh'));
    await tester.pumpAndSettle();
    expect(find.text('GPS bị từ chối'), findsOneWidget);
    expect(find.text('GPS đã bật · Sẵn sàng điểm danh'), findsNothing);
  });
  testWidgets(
    'scanner has gallery action and unavailable torch stays disabled',
    (tester) async {
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QrScanSurface(onGallery: () => opened = true)),
        ),
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Đèn pin'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Thư viện'));
      expect(opened, isTrue);
    },
  );
}
