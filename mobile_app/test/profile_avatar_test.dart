import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/profile_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/device_photo_picker.dart';
import 'package:tho_xay_mobile/widgets/user_avatar.dart';
import 'package:tho_xay_mobile/widgets/photo_preview_dialog.dart';

import 'settings_screen_test.dart' show SettingsApi;

final pixel = TileProvider.transparentImage;

class _Picker extends DevicePhotoPicker {
  bool cancelled = false;
  @override
  Future<Uint8List?> pick(ImageSource source) async => cancelled ? null : pixel;
}

class _ProfileApi extends SettingsApi {
  int uploads = 0;
  bool fail = false;
  String? avatar;
  @override
  Future<UserProfile> profile() async => UserProfile(
    id: 3,
    fullName: 'Nguyễn Văn An',
    phoneNumber: '0900000003',
    role: 'ROLE_WORKER',
    verified: true,
    rating: 5,
    experienceYears: 5,
    skills: const ['Xây tô'],
    avatarUrl: avatar,
  );
  @override
  Future<UserProfile> uploadAvatar(Uint8List bytes) async {
    uploads++;
    if (fail) throw const ApiException('Không lưu được ảnh');
    avatar = '/api/users/3/avatar?v=new';
    return profile();
  }

  @override
  Future<Uint8List> privateImage(String path) async => pixel;
}

class _UploadClient extends http.BaseClient {
  int uploads = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    Object data;
    if (request.url.path == '/api/auth/login') {
      data = {
        'userId': 3,
        'fullName': 'Worker',
        'phoneNumber': '0900000003',
        'role': 'ROLE_WORKER',
        'token': 'jwt',
        'expiresIn': 3600,
      };
    } else {
      uploads++;
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/users/me/avatar');
      expect(request.headers['Authorization'], 'Bearer jwt');
      final form = request as http.MultipartRequest;
      expect(form.fields, isEmpty);
      expect(form.files.single.field, 'photo');
      expect(await form.files.single.finalize().toBytes(), pixel);
      data = {
        'id': 3,
        'fullName': 'Worker',
        'phoneNumber': '0900000003',
        'role': 'ROLE_WORKER',
        'verified': true,
        'rating': 5,
        'avatarUrl': '/api/users/3/avatar?v=next',
      };
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(data))),
      200,
    );
  }
}

void main() {
  testWidgets(
    'invalid avatar preview shows a readable error and disables upload without crashing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPreviewDialog(
              bytes: Uint8List.fromList([1, 2, 3]),
              showCaption: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Không đọc được ảnh.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('avatar upload uses authenticated current-user multipart PUT', () async {
    final client = _UploadClient();
    final actual = ApiService(client: client);
    await actual.login('0900000003', 'Password123');
    final profile = await actual.uploadAvatar(pixel);
    expect(profile.avatarUrl, '/api/users/3/avatar?v=next');
    expect(profile.verified, isTrue);
    expect(client.uploads, 1);
    await expectLater(
      actual.uploadAvatar(Uint8List(0)),
      throwsA(isA<ApiException>()),
    );
    expect(client.uploads, 1);
    actual.dispose();
  });
  Future<void> mount(
    WidgetTester tester,
    _ProfileApi api,
    _Picker picker,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(api: api, photoPicker: picker),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester) async {
    await tester.tap(find.text('Đổi ảnh đại diện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn từ thư viện'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'profile has visible utility groups and no accordions or hidden personal form',
    (tester) async {
      await mount(tester, _ProfileApi(), _Picker());
      expect(find.byType(ExpansionTile), findsNothing);
      for (final label in [
        'Tiện ích nghề nghiệp',
        'Lịch làm việc',
        'Tổ đội của tôi',
        'Công trình yêu thích',
        'Lịch sử uy tín',
        'Bảng xếp hạng thợ',
        'Sự cố đã gửi',
        'Thông tin cá nhân & kinh nghiệm',
        'Xác thực CCCD',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(TextFormField), findsNothing);
      await tester.ensureVisible(find.text('Chỉnh sửa thông tin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa thông tin'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Họ và tên'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'avatar is previewed and uploaded only after confirmation, then renders actual bytes',
    (tester) async {
      final api = _ProfileApi();
      await mount(tester, api, _Picker());
      await choose(tester);
      expect(api.uploads, 0);
      expect(find.text('Xác nhận ảnh đại diện'), findsOneWidget);
      await tester.tap(find.text('Dùng ảnh này'));
      await tester.pumpAndSettle();
      expect(api.uploads, 1);
      expect(
        find.descendant(
          of: find.byType(UserAvatar),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      expect(find.text('Đã cập nhật ảnh đại diện.'), findsOneWidget);
      expect(find.text('Định danh CCCD: Đã xác thực'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'cancelled selection never uploads; server failure preserves the prior avatar',
    (tester) async {
      final api = _ProfileApi(), picker = _Picker()..cancelled = true;
      await mount(tester, api, picker);
      await choose(tester);
      expect(api.uploads, 0);
      expect(find.text('Xác nhận ảnh đại diện'), findsNothing);
      picker.cancelled = false;
      api.fail = true;
      await choose(tester);
      await tester.tap(find.text('Dùng ảnh này'));
      await tester.pumpAndSettle();
      expect(api.avatar, isNull);
      expect(find.text('Không lưu được ảnh'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
