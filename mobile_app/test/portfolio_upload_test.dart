import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/models/portfolio_photo.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/device_photo_picker.dart';
import 'package:tho_xay_mobile/widgets/portfolio_uploads.dart';
import 'package:tho_xay_mobile/widgets/private_image.dart';

final bytes = TileProvider.transparentImage;

class Picker extends DevicePhotoPicker {
  @override
  Future<Uint8List?> pick(ImageSource source) async => bytes;
}

class PhotosApi extends ApiService {
  List<PortfolioPhoto> items = [];
  int uploads = 0, deletes = 0;
  String? caption;
  @override
  Future<List<PortfolioPhoto>> portfolio(int id) async => List.of(items);
  @override
  Future<Uint8List> privateImage(String path) async => bytes;
  @override
  Future<PortfolioPhoto> uploadPortfolio(Uint8List b, String text) async {
    uploads++;
    caption = text;
    final photo = PortfolioPhoto(id: 'qa-photo', caption: text);
    items.add(photo);
    return photo;
  }

  @override
  Future<void> deletePortfolio(String id) async {
    deletes++;
    items.removeWhere((p) => p.id == id);
  }
}

class PhotoClient extends http.BaseClient {
  bool locked = false;
  int images = 0, uploads = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path == '/api/auth/login') {
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'token': 'jwt',
              'userId': 3,
              'fullName': 'QA',
              'phoneNumber': '0999999999',
              'role': 'ROLE_WORKER',
              'expiresIn': 3600,
            }),
          ),
        ),
        200,
      );
    }
    expect(request.url.query, isEmpty);
    expect(request.headers['Authorization'], 'Bearer jwt');
    expect(request.followRedirects, isFalse);
    if (locked) {
      return http.StreamedResponse(
        Stream.value(
          utf8.encode('{"code":"ACCOUNT_LOCKED","message":"locked"}'),
        ),
        403,
      );
    }
    if (request is http.MultipartRequest) {
      uploads++;
      expect(request.files.single.field, 'photo');
      expect(request.fields['caption'], 'Ảnh QA');
      return http.StreamedResponse(
        Stream.value(utf8.encode('{"id":"test-id","caption":"Ảnh QA"}')),
        200,
      );
    }
    images++;
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'image/jpeg'},
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'photo upload and read use bearer header and never put JWT in URL',
    () async {
      final client = PhotoClient();
      final api = ApiService(client: client);
      await api.login('0999999999', 'password');
      await api.uploadPortfolio(bytes, 'Ảnh QA');
      expect(await api.privateImage('/api/portfolio/photos/test-id'), bytes);
      expect(client.uploads, 1);
      expect(client.images, 1);
      await expectLater(
        api.privateImage('https://evil.example/image'),
        throwsA(isA<ApiException>()),
      );
      client.locked = true;
      await expectLater(
        api.privateImage('/api/portfolio/photos/test-id'),
        throwsA(isA<ApiException>()),
      );
      expect(api.session, isNull);
      api.dispose();
    },
  );
  testWidgets(
    'photo preview requires confirmation and then lists persisted caption',
    (tester) async {
      final api = PhotosApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioUploads(
                api: api,
                ownerId: 3,
                editable: true,
                picker: Picker(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          MemoryImage(bytes),
          tester.element(find.byType(PortfolioUploads)),
        ),
      );
      await tester.tap(find.text('Thêm ảnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn từ thư viện'));
      await tester.pumpAndSettle();
      expect(api.uploads, 0);
      expect(find.text('Xem trước ảnh dự án'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ốp lát phòng khách');
      await tester.tap(find.text('Tải ảnh lên'));
      await tester.pumpAndSettle();
      expect(api.uploads, 1);
      expect(api.caption, 'Ốp lát phòng khách');
      expect(find.text('Ốp lát phòng khách'), findsOneWidget);
      await tester.tap(find.byType(PrivateImage));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng ảnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa ảnh'));
      await tester.pumpAndSettle();
      expect(api.deletes, 0);
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa ảnh'));
      await tester.pumpAndSettle();
      expect(api.deletes, 1);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('public profile gallery has no add or delete controls', (
    tester,
  ) async {
    final api = PhotosApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PortfolioUploads(api: api, ownerId: 3)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thêm ảnh'), findsNothing);
    expect(find.text('Xóa ảnh'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
