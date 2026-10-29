import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tho_xay_mobile/models/chat_message.dart';
import 'package:tho_xay_mobile/screens/chat_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/device_photo_picker.dart';
import 'package:tho_xay_mobile/services/location_service.dart';

import 'support/fake_chat_api.dart';

final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

class _Picker extends DevicePhotoPicker {
  @override
  Future<Uint8List?> pick(ImageSource source) async => _pixel;
}

class _Location extends LocationService {
  bool denied = false;
  @override
  Future<GeoPoint> currentPosition() async {
    if (denied) throw const LocationFailure('GPS bị từ chối');
    return const GeoPoint(10.762622, 106.660172);
  }
}

class _MediaApi extends FakeChatApi {
  final payloads = <String>[];
  @override
  Future<Uint8List> privateImage(String path) async => _pixel;
  Future<ChatMessage> _save(
    String key,
    String content,
    String kind, {
    double? lat,
    double? lng,
  }) async {
    sentIds.add(key);
    payloads.add('$kind:$content:$lat:$lng');
    final old = rows.where((m) => m.clientMessageId == key).firstOrNull;
    final result =
        old ??
        ChatMessage(
          id: rows.length + 1,
          senderId: 3,
          recipientId: 2,
          jobId: 1,
          content: content,
          createdAt: DateTime.utc(2026),
          clientMessageId: key,
          kind: kind,
          latitude: lat,
          longitude: lng,
          imagePath: kind == 'IMAGE' ? '/api/jobs/1/messages/1/photo' : null,
        );
    if (old == null) {
      rows.add(result);
      connections.last.add(messageEvent(result));
    }
    if (failSendOnce) {
      failSendOnce = false;
      throw const ApiException('Mất phản hồi');
    }
    return result;
  }

  @override
  Future<ChatMessage> sendChatPhoto(
    int jobId,
    int peerId,
    Uint8List bytes,
    String caption,
    String clientId,
  ) => _save(clientId, caption, 'IMAGE');
  @override
  Future<ChatMessage> sendChatLocation(
    int jobId,
    int peerId,
    double latitude,
    double longitude,
    String clientId,
  ) => _save(
    clientId,
    'Vị trí được chia sẻ',
    'LOCATION',
    lat: latitude,
    lng: longitude,
  );
}

Future<void> _open(
  WidgetTester tester,
  _MediaApi api, {
  _Location? location,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        api: api,
        job: chatJob,
        peerId: 2,
        peerName: 'Chủ thầu',
        picker: _Picker(),
        location: location ?? _Location(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Đính kèm ảnh hoặc vị trí'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'photo waits for confirmation and failed retry keeps key and caption',
    (tester) async {
      final api = _MediaApi()..failSendOnce = true;
      await _open(tester, api);
      await tester.tap(find.text('Chọn ảnh từ thư viện'));
      await tester.pumpAndSettle();
      expect(api.sentIds, isEmpty);
      await tester.enterText(
        find.widgetWithText(TextField, 'Chú thích ảnh'),
        'Tiến độ hôm nay',
      );
      await tester.tap(find.text('Xác nhận gửi'));
      await tester.pumpAndSettle();
      expect(find.text('Gửi lại'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Chú thích ảnh'))
            .enabled,
        isFalse,
      );
      await tester.tap(find.text('Gửi lại'));
      await tester.pumpAndSettle();
      expect(api.sentIds[0], api.sentIds[1]);
      expect(api.payloads[0], api.payloads[1]);
      expect(api.rows, hasLength(1));
      expect(find.text('Tiến độ hôm nay'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('GPS permission denial never sends location', (tester) async {
    final api = _MediaApi();
    await _open(tester, api, location: _Location()..denied = true);
    await tester.tap(find.text('Chia sẻ vị trí GPS'));
    await tester.pumpAndSettle();
    expect(find.text('GPS bị từ chối'), findsOneWidget);
    expect(api.sentIds, isEmpty);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(api.rows, isEmpty);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('GPS preview confirms exact coordinates and renders map action', (
    tester,
  ) async {
    final api = _MediaApi();
    await _open(tester, api);
    await tester.tap(find.text('Chia sẻ vị trí GPS'));
    await tester.pumpAndSettle();
    expect(find.text('10.762622, 106.660172'), findsOneWidget);
    expect(api.sentIds, isEmpty);
    await tester.tap(find.text('Xác nhận gửi'));
    await tester.pumpAndSettle();
    expect(api.rows.single.latitude, 10.762622);
    expect(api.rows.single.longitude, 106.660172);
    expect(find.text('Mở vị trí trên bản đồ'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
