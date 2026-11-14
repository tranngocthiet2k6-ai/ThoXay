import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/models/app_notification.dart';
import 'package:tho_xay_mobile/models/incident.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/worker_profile.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/screens/earnings_screen.dart';
import 'package:tho_xay_mobile/screens/profile_screen.dart';
import 'package:tho_xay_mobile/screens/saved_screen.dart';
import 'package:tho_xay_mobile/screens/support_center_screen.dart';
import 'package:tho_xay_mobile/screens/wallet_screen.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/theme/appearance_controller.dart';
import 'package:tho_xay_mobile/widgets/brand_logo.dart';
import 'package:tho_xay_mobile/widgets/home_navigation.dart';

import 'wallet_test.dart' show WalletApi;

class _NavigationApi extends WalletApi {
  _NavigationApi(this.role);
  final String role;
  int refreshes = 0;
  bool loggedOut = false;
  bool badgeFailure = false;
  int chatCount = 3, noticeCount = 7;
  @override
  AuthSession? get session => loggedOut
      ? null
      : AuthSession(
          token: 'test',
          userId: 3,
          fullName: 'Thợ Xây',
          phoneNumber: '0900000003',
          role: role,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
  @override
  Future<bool> availability() async {
    refreshes++;
    return false;
  }

  @override
  Future<List<Job>> contractorJobs() async {
    refreshes++;
    return [];
  }

  @override
  Future<List<JobApplication>> workerApplications() async => [];
  @override
  Future<List<WorkerProfile>> savedWorkers() async => [];
  @override
  Future<int> unreadMessages() async {
    if (badgeFailure) throw const ApiException('Mất kết nối');
    return chatCount;
  }

  @override
  Future<NotificationPage> notifications({int? beforeId}) async {
    if (badgeFailure) throw const ApiException('Mất kết nối');
    return NotificationPage([], false, noticeCount);
  }

  @override
  Future<UserProfile> profile() async => UserProfile(
    id: 3,
    fullName: 'Người thợ',
    phoneNumber: '0900000003',
    role: role,
    verified: false,
    rating: 5,
  );
  @override
  Future<IncidentPage> myIncidents({int? jobId, int? beforeId}) async =>
      IncidentPage.fromJson({'items': [], 'hasMore': false});
  @override
  Future<void> logout() async {
    loggedOut = true;
    notifyListeners();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'badges retain confirmed counts offline, cap at 99+ and clear on logout',
    (tester) async {
      final api = _NavigationApi('ROLE_WORKER');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: [HomeInboxActions(api: api)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chat = find.byKey(const ValueKey('home-chat-action'));
      Badge badge() => tester.widget<Badge>(
        find.descendant(of: chat, matching: find.byType(Badge)),
      );
      expect((badge().label as Text).data, '3');
      api.badgeFailure = true;
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect((badge().label as Text).data, '3');
      api.badgeFailure = false;
      api.chatCount = 140;
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect((badge().label as Text).data, '99+');
      await api.logout();
      await tester.pumpAndSettle();
      expect(badge().isLabelVisible, isFalse);
      expect((badge().label as Text).data, '0');
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  for (final worker in [true, false]) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'four core tabs and three AppBar actions: worker=$worker width=$width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = _NavigationApi(
            worker ? 'ROLE_WORKER' : 'ROLE_CONTRACTOR',
          );
          final appearance = AppearanceController();
          await tester.pumpWidget(
            AppearanceScope(
              controller: appearance,
              child: MaterialApp(
                theme: AppTheme.forRole(api.role),
                home: worker
                    ? WorkerHomeScreen(api: api)
                    : ContractorHomeScreen(api: api),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final nav = find.byType(NavigationBar);
          final labels = tester
              .widgetList<NavigationDestination>(
                find.descendant(
                  of: nav,
                  matching: find.byType(NavigationDestination),
                ),
              )
              .map((d) => d.label)
              .toList();
          expect(
            labels,
            worker
                ? ['Tìm việc', 'Việc của tôi', 'Ví tiền', 'Hồ sơ']
                : ['Công trình', 'Đội thợ', 'Ví tiền', 'Hồ sơ'],
          );
          expect(
            find.descendant(of: nav, matching: find.byType(BrandLogo)),
            findsNothing,
          );
          expect(find.byType(BrandLogo), findsOneWidget);
          final bar = find.byType(AppBar);
          expect(
            find.descendant(of: bar, matching: find.byType(IconButton)),
            findsNWidgets(3),
          );
          expect(find.byTooltip('Tin nhắn'), findsOneWidget);
          expect(find.byTooltip('Thông báo'), findsOneWidget);
          expect(find.byTooltip('Cài đặt'), findsOneWidget);
          expect(find.byTooltip('Giao diện hiển thị'), findsNothing);
          expect(find.byTooltip('Thu nhập & Ví'), findsNothing);
          expect(
            find.descendant(of: bar, matching: find.text('3')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: bar, matching: find.text('7')),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Cài đặt'));
          await tester.pumpAndSettle();
          for (final label in [
            'Tài khoản & Bảo mật',
            'Hiển thị & Trải nghiệm công trường',
            'Thông báo & Khu vực',
            'Hỗ trợ & Pháp lý',
          ]) {
            expect(find.text(label), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          appearance.dispose();
          api.dispose();
        },
      );
    }
  }

  testWidgets(
    'worker switches history and routes wallet and profile to their correct tabs',
    (tester) async {
      final api = _NavigationApi('ROLE_WORKER');
      await tester.pumpWidget(MaterialApp(home: WorkerHomeScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Việc của tôi'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(find.text('Lịch làm việc'), findsWidgets);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Ví tiền'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WalletScreen), findsOneWidget);
      await tester.tap(find.text('Xem thu nhập chi tiết'));
      await tester.pumpAndSettle();
      expect(find.byType(EarningsScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(EarningsScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Hồ sơ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'contractor crew tab opens saved workers and does not open posting form',
    (tester) async {
      final api = _NavigationApi('ROLE_CONTRACTOR');
      await tester.pumpWidget(
        MaterialApp(home: ContractorHomeScreen(api: api)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Đội thợ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SavedScreen), findsOneWidget);
      expect(
        tester.widget<SavedScreen>(find.byType(SavedScreen)).worker,
        isFalse,
      );
      expect(find.text('+ Đăng công trình mới'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'overflow menu changes modes, refreshes data, opens support and logs out',
    (tester) async {
      final api = _NavigationApi('ROLE_WORKER');
      final appearance = AppearanceController();
      await tester.pumpWidget(
        AppearanceScope(
          controller: appearance,
          child: ListenableBuilder(
            listenable: appearance,
            builder: (_, child) => MaterialApp(
              theme: AppTheme.forRole(
                api.role,
                brightness: appearance.brightness,
                outdoor: appearance.mode == DisplayMode.outdoor,
              ),
              home: Scaffold(
                appBar: AppBar(
                  actions: [
                    HomeAppMenu(
                      api: api,
                      onRefresh: () async {
                        await api.availability();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> select(String label) async {
        await tester.tap(find.byTooltip('Tùy chọn'));
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byWidgetPredicate(
                  (widget) => widget is PopupMenuEntry,
                ),
              )
              .first,
        );
        await tester.pumpAndSettle();
      }

      await select('Chế độ Tối');
      expect(appearance.mode, DisplayMode.dark);
      await select('Tương phản cao (Ngoài trời)');
      expect(appearance.mode, DisplayMode.outdoor);
      await select('Chế độ Sáng');
      expect(appearance.mode, DisplayMode.light);
      final refreshed = api.refreshes;
      await select('Làm mới dữ liệu');
      expect(api.refreshes, refreshed + 1);
      await select('Trung tâm hỗ trợ & SOS');
      expect(find.byType(SupportCenterScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(SupportCenterScreen))).pop();
      await tester.pumpAndSettle();
      await select('Đăng xuất');
      expect(api.loggedOut, isTrue);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
      api.dispose();
    },
  );
}
