import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/device_photo_picker.dart';
import 'package:tho_xay_mobile/screens/register_screen.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/work_photo_report_dialog.dart';

class Photos extends DevicePhotoPicker {
  bool cancel = false;
  @override
  Future<Uint8List?> pick(ImageSource source) async =>
      cancel ? null : TileProvider.transparentImage;
}

void main() {
  testWidgets(
    'two-photo report requires both images and returns only after explicit send',
    (tester) async {
      final picker = Photos();
      WorkPhotoDraft? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  submitted = await showDialog<WorkPhotoDraft>(
                    context: context,
                    builder: (_) => WorkPhotoReportDialog(picker: picker),
                  );
                },
                child: const Text('Mở báo cáo'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở báo cáo'));
      await tester.pumpAndSettle();
      FilledButton send() =>
          tester.widget(find.widgetWithText(FilledButton, 'Gửi báo cáo'));
      expect(send().onPressed, isNull);
      await tester.tap(find.byTooltip('Chọn ảnh toàn cảnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn từ thư viện'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1/2 ảnh'), findsOneWidget);
      expect(send().onPressed, isNull);
      expect(submitted, isNull);
      picker.cancel = true;
      await tester.tap(find.byTooltip('Chọn ảnh chi tiết'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chụp bằng camera'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1/2 ảnh'), findsOneWidget);
      expect(send().onPressed, isNull);
      picker.cancel = false;
      await tester.tap(find.byTooltip('Chọn ảnh chi tiết'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn từ thư viện'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Tô xong tường phòng khách',
      );
      expect(submitted, isNull);
      expect(send().onPressed, isNotNull);
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(submitted!.overview, TileProvider.transparentImage);
      expect(submitted!.detail, TileProvider.transparentImage);
      expect(submitted!.caption, 'Tô xong tường phòng khách');
      expect(tester.takeException(), isNull);
    },
  );
  test('work report sends two multipart parts with current-user JWT and one shared day', () async {
    SharedPreferences.setMockInitialValues({});
    var uploads = 0;
    final api = ApiService(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'token': 'qa',
              'userId': 3,
              'fullName': 'QA',
              'phoneNumber': '0900000003',
              'role': 'ROLE_WORKER',
              'expiresIn': 3600,
            }),
            200,
          );
        }
        uploads++;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/applications/7/work-logs');
        expect(request.headers['Authorization'], 'Bearer qa');
        final raw = latin1.decode(request.bodyBytes);
        expect(raw, contains('name="photo"'));
        expect(raw, contains('name="detailPhoto"'));
        expect(raw, contains('2030-03-01'));
        return http.Response(
          '{"today":"2030-03-01","items":[],"hasMore":false}',
          200,
        );
      }),
    );
    await api.login('0900000003', 'password');
    await api.uploadWorkPhotos(
      7,
      DateTime(2030, 3, 1),
      TileProvider.transparentImage,
      TileProvider.transparentImage,
      'Tiến độ',
    );
    expect(uploads, 1);
    api.dispose();
  });
  testWidgets(
    'registration role cards preview contractor palette without changing authentication permissions',
    (tester) async {
      final api = ApiService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RegisterScreen(api: api),
        ),
      );
      await tester.tap(find.text('Tôi là chủ thầu'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary,
        AppTheme.contractorEmerald,
      );
      expect(api.session, isNull);
      expect(tester.takeException(), isNull);
      api.dispose();
    },
  );
}
