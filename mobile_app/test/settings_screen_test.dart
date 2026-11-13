import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/profile_screen.dart';
import 'package:tho_xay_mobile/screens/settings_screen.dart';
import 'package:tho_xay_mobile/screens/support_center_screen.dart';
import 'package:tho_xay_mobile/screens/incidents_screen.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/device_preferences.dart';
import 'package:tho_xay_mobile/services/push_notifications.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/theme/appearance_controller.dart';
import 'package:tho_xay_mobile/widgets/account_security_sheet.dart';
import 'package:tho_xay_mobile/widgets/bouncing_button.dart';
import 'package:tho_xay_mobile/widgets/profile_settings.dart';

import 'wallet_test.dart' show WalletApi;
import 'worker_home_test.dart' show WorkerApi, FixedLocation;

class RadiusApi extends WorkerApi {
  double? searchedRadius;
  @override
  Future<List<Job>> nearby(
    double lat,
    double lng,
    double radius, {
    String? jobType,
    String sort = 'DISTANCE',
  }) async {
    searchedRadius = radius;
    return [];
  }
}

class SettingsApi extends WalletApi {
  bool jobs = true, chat = true, failPush = false, failLoad = false;
  int logoutCount = 0, passwordCount = 0, phoneCount = 0;
  String? oldPassword, newPassword, newPhone;
  Completer<void>? passwordWait;
  String? passwordError;
  @override
  AuthSession get session => AuthSession(
    token: 'qa',
    userId: 3,
    fullName: 'Nguyễn Văn An',
    phoneNumber: '0900000003',
    role: 'ROLE_WORKER',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  @override
  Future<Map<String, bool>> notificationPreferences() async {
    if (failLoad) throw const ApiException('Mất kết nối');
    return {'jobPushEnabled': jobs, 'chatPushEnabled': chat};
  }

  @override
  Future<void> setNotificationPreferences({
    required bool jobs,
    required bool chat,
  }) async {
    if (failPush) throw const ApiException('Không lưu được thông báo');
    this.jobs = jobs;
    this.chat = chat;
  }

  @override
  Future<void> logout() async {
    logoutCount++;
  }

  @override
  Future<void> changePassword(String old, String next) async {
    passwordCount++;
    oldPassword = old;
    newPassword = next;
    if (passwordError != null) throw ApiException(passwordError!);
    await passwordWait?.future;
  }

  @override
  Future<void> changePhone(String phone, String password) async {
    phoneCount++;
    oldPassword = password;
    newPhone = phone;
  }

  @override
  Future<UserProfile> profile() async => UserProfile(
    id: 3,
    fullName: 'Nguyễn Văn An',
    phoneNumber: '0900000003',
    role: 'ROLE_WORKER',
    verified: true,
    rating: 5,
    cccdFrontImage: 'https://example.com/front.png',
    cccdBackImage: 'https://example.com/back.png',
  );
}

class SettingsPush implements PushClient {
  int enables = 0;
  @override
  bool get configured => true;
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<String> enable(ApiService api) async {
    enables++;
    return 'Đã kiểm tra quyền nhận thông báo';
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DevicePreferences.instance.restore();
  });
  Future<void> mount(
    WidgetTester tester,
    SettingsApi api, {
    AppearanceController? appearance,
    double width = 390,
    Widget? child,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = appearance ?? AppearanceController();
    if (appearance == null) addTearDown(controller.dispose);
    addTearDown(api.dispose);
    await tester.pumpWidget(
      AppearanceScope(
        controller: controller,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.forRole(
              'ROLE_WORKER',
              brightness: controller.brightness,
              outdoor: controller.mode == DisplayMode.outdoor,
            ),
            home: child ?? SettingsScreen(api: api),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text).first;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Finder toggle(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
    matching: find.byType(Switch),
  );

  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets(
      'settings four groups, quiet cards and release metadata fit $width',
      (tester) async {
        await mount(tester, SettingsApi(), width: width);
        for (final label in [
          'Tài khoản & Bảo mật',
          'Hiển thị & Trải nghiệm công trường',
          'Thông báo & Khu vực',
          'Hỗ trợ & Pháp lý',
          'Thợ Xây v1.0.0',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        await tester.ensureVisible(find.text('Thợ Xây v1.0.0'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final theme = Theme.of(tester.element(find.byType(ProfileSettings)));
        expect(theme.scaffoldBackgroundColor, const Color(0xfff6f7f9));
        expect(theme.cardTheme.elevation, 0);
        expect(
          (theme.cardTheme.shape! as RoundedRectangleBorder).side,
          BorderSide.none,
        );
        expect(theme.textTheme.titleLarge!.fontSize, 20);
        expect(theme.textTheme.titleMedium!.fontSize, 15);
        expect(theme.textTheme.bodySmall!.fontSize, 13);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'profile gear opens dedicated settings and account/KYC has editable details',
    (tester) async {
      final api = SettingsApi();
      await mount(tester, api, child: ProfileScreen(api: api));
      expect(find.byType(ProfileSettings), findsNothing);
      await tester.tap(find.byTooltip('Cài đặt'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tapText(tester, 'Thông tin cá nhân & KYC');
      expect(
        tester
            .widget<ProfileScreen>(find.byType(ProfileScreen).last)
            .accountDetails,
        isTrue,
      );
      expect(find.widgetWithText(TextFormField, 'Họ và tên'), findsOneWidget);
      expect(find.text('0900000003'), findsWidgets);
      expect(find.text('Định danh CCCD: Đã xác thực'), findsOneWidget);
      expect(find.byTooltip('Cài đặt'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'display switches persist modes; outdoor cards retain visible boundaries',
    (tester) async {
      final appearance = AppearanceController();
      addTearDown(appearance.dispose);
      await mount(tester, SettingsApi(), appearance: appearance);
      await tapText(tester, 'Giao diện Sáng / Tối');
      expect(appearance.mode, DisplayMode.dark);
      await tapText(tester, 'Tương phản cao (Ngoài trời)');
      expect(appearance.mode, DisplayMode.outdoor);
      final restored = AppearanceController();
      await restored.restore();
      expect(restored.mode, DisplayMode.outdoor);
      restored.dispose();
      final theme = Theme.of(tester.element(find.byType(ProfileSettings)));
      expect((theme.cardTheme.shape! as RoundedRectangleBorder).side.width, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'haptics switch is persisted and actually suppresses platform feedback',
    (tester) async {
      var impacts = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') impacts++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await mount(tester, SettingsApi());
      await tester.ensureVisible(toggle('Rung phản hồi xúc giác'));
      await tester.pumpAndSettle();
      await tester.tap(toggle('Rung phản hồi xúc giác'));
      await tester.pumpAndSettle();
      expect(DevicePreferences.instance.haptics, isFalse);
      AppHaptics.light();
      await tester.pump();
      expect(impacts, 0);
      final restored = DevicePreferences();
      await restored.restore();
      expect(restored.haptics, isFalse);
      restored.dispose();
      await tester.tap(toggle('Rung phản hồi xúc giác'));
      await tester.pumpAndSettle();
      expect(impacts, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('radius selector persists only supported search radii', (
    tester,
  ) async {
    await mount(tester, SettingsApi());
    await tapText(tester, '50 km');
    final restored = DevicePreferences();
    await restored.restore();
    expect(restored.radius, 50);
    expect(await restored.setRadius(200), isFalse);
    expect(restored.radius, 50);
    restored.dispose();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'push categories save independently, request device permission and revert on failure',
    (tester) async {
      final api = SettingsApi(), push = SettingsPush();
      await mount(
        tester,
        api,
        child: Scaffold(
          body: SingleChildScrollView(
            child: ProfileSettings(api: api, push: push),
          ),
        ),
      );
      await tester.ensureVisible(toggle('Thông báo công việc'));
      await tester.pumpAndSettle();
      await tester.tap(toggle('Thông báo công việc'));
      await tester.pumpAndSettle();
      expect(api.jobs, isFalse);
      expect(api.chat, isTrue);
      await tester.tap(toggle('Thông báo công việc'));
      await tester.pumpAndSettle();
      expect(push.enables, 1);
      api.failPush = true;
      await tester.tap(toggle('Thông báo công việc'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Switch>(toggle('Thông báo công việc')).value,
        isTrue,
      );
      expect(find.text('Không lưu được thông báo'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'notification preference load failure disables toggles and supports retry',
    (tester) async {
      final api = SettingsApi()..failLoad = true;
      await mount(tester, api);
      expect(
        tester.widget<Switch>(toggle('Thông báo công việc')).onChanged,
        isNull,
      );
      api.failLoad = false;
      await tapText(tester, 'Tải lại lựa chọn');
      expect(
        tester.widget<Switch>(toggle('Thông báo công việc')).onChanged,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('terms and privacy open substantive sheets with close controls', (
    tester,
  ) async {
    await mount(tester, SettingsApi());
    await tapText(tester, 'Điều khoản sử dụng');
    expect(find.text('1. Phạm vi sử dụng'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('không tự xác nhận đã nhận tiền'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.textContaining('không tự xác nhận đã nhận tiền'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Chính sách bảo mật');
    expect(find.text('1. Dữ liệu được xử lý'), findsOneWidget);
    expect(find.textContaining('Ứng dụng xử lý số điện thoại'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Hotline hỗ trợ'), findsOneWidget);
    expect(find.text('0339971407'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'logout can be cancelled and is sent exactly once after confirmation',
    (tester) async {
      final api = SettingsApi();
      await mount(tester, api);
      await tapText(tester, 'Đăng xuất');
      expect(api.logoutCount, 0);
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(api.logoutCount, 0);
      await tapText(tester, 'Đăng xuất');
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
      await tester.pumpAndSettle();
      expect(api.logoutCount, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'password sheet validates strength/confirmation, reports server errors and prevents duplicate submit',
    (tester) async {
      final api = SettingsApi();
      await mount(tester, api);
      await tapText(tester, 'Đổi mật khẩu');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Oldpass123');
      await tester.enterText(fields.at(1), 'weak');
      await tester.enterText(fields.at(2), 'different');
      await tapText(tester, 'Lưu thay đổi');
      expect(api.passwordCount, 0);
      expect(find.textContaining('Dùng ít nhất 8 ký tự'), findsOneWidget);
      await tester.enterText(fields.at(1), 'Newpass456');
      await tester.enterText(fields.at(2), 'Newpass456');
      api.passwordError = 'Mật khẩu hiện tại không đúng';
      await tapText(tester, 'Lưu thay đổi');
      expect(find.text(api.passwordError!), findsOneWidget);
      api.passwordError = null;
      api.passwordWait = Completer<void>();
      await tapText(tester, 'Lưu thay đổi');
      expect(api.passwordCount, 2);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Đang lưu…'),
            )
            .onPressed,
        isNull,
      );
      api.passwordWait!.complete();
      await tester.pumpAndSettle();
      expect(api.oldPassword, 'Oldpass123');
      expect(api.newPassword, 'Newpass456');
      expect(find.byType(AccountSecuritySheet), findsNothing);
      expect(find.textContaining('Đổi mật khẩu thành công'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('saved radius is used by actual nearby jobs request', (
    tester,
  ) async {
    await DevicePreferences.instance.setRadius(50);
    final api = RadiusApi();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerHomeScreen(api: api, location: FixedLocation()),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.searchedRadius, 50);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('support links open quick guidance and incident tracking', (
    tester,
  ) async {
    await mount(tester, SettingsApi());
    await tapText(tester, 'Trung tâm trợ giúp & SOS');
    expect(find.byType(SupportCenterScreen), findsOneWidget);
    expect(find.textContaining('1. Chọn công trình liên quan'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapText(tester, 'Theo dõi sự cố & khiếu nại');
    expect(find.byType(IncidentsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'hotline launches the confirmed phone and gracefully handles missing dialer',
    (tester) async {
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      String? called;
      bool fail = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (fail) throw PlatformException(code: 'NO_DIALER');
        called = (call.arguments as Map)['url'] as String?;
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await mount(tester, SettingsApi());
      await tapText(tester, 'Hotline hỗ trợ');
      expect(called, 'tel:0339971407');
      fail = true;
      await tapText(tester, 'Hotline hỗ trợ');
      expect(
        find.textContaining('Không mở được ứng dụng gọi điện'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'phone sheet validates phone and sends password to authenticated API',
    (tester) async {
      final api = SettingsApi();
      await mount(
        tester,
        api,
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showAccountSecuritySheet(context, api, phone: true),
              child: const Text('Mở đổi số'),
            ),
          ),
        ),
      );
      await tapText(tester, 'Mở đổi số');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Oldpass123');
      await tester.enterText(fields.at(1), 'abc');
      await tapText(tester, 'Lưu thay đổi');
      expect(api.phoneCount, 0);
      await tester.enterText(fields.at(1), '0988881234');
      await tapText(tester, 'Lưu thay đổi');
      expect(api.newPhone, '0988881234');
      expect(api.oldPassword, 'Oldpass123');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
