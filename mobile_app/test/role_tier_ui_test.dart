import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/tier_guide.dart';
import 'package:tho_xay_mobile/models/worker_profile.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/screens/login_screen.dart';
import 'package:tho_xay_mobile/screens/register_screen.dart';
import 'package:tho_xay_mobile/screens/settings_screen.dart';
import 'package:tho_xay_mobile/screens/tier_details_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/chat_contact.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/figma_components.dart';
import 'package:tho_xay_mobile/widgets/role_switch_tile.dart';
import 'package:tho_xay_mobile/widgets/tier_badge.dart';

import 'settings_screen_test.dart' show SettingsApi;
import 'support/fake_chat_api.dart' show chatJob;

const guideFixture = {
  'tiers': [
    {
      'code': 'BRONZE',
      'name': 'Đồng · Khởi đầu',
      'minReputation': 0,
      'minCompletedJobs': 0,
      'minRating': 0,
      'requiresKyc': false,
      'benefits': ['Hồ sơ và ứng tuyển'],
    },
    {
      'code': 'SILVER',
      'name': 'Bạc',
      'minReputation': 60,
      'minCompletedJobs': 1,
      'minRating': 3.0,
      'requiresKyc': false,
      'benefits': ['Ưu tiên trước Đồng'],
    },
    {
      'code': 'GOLD',
      'name': 'Vàng',
      'minReputation': 80,
      'minCompletedJobs': 5,
      'minRating': 4.0,
      'requiresKyc': false,
      'benefits': ['Ưu tiên trước Bạc'],
    },
    {
      'code': 'DIAMOND',
      'name': 'Kim Cương',
      'minReputation': 95,
      'minCompletedJobs': 20,
      'minRating': 4.7,
      'requiresKyc': true,
      'benefits': ['Ưu tiên theo bậc cao nhất'],
    },
  ],
  'priorityPolicy': 'Ưu tiên sắp xếp ứng viên; không tự động duyệt.',
  'feePolicy': 'Giảm phí theo bậc chưa áp dụng.',
};

class RoleTierApi extends SettingsApi {
  String activeRole = 'ROLE_WORKER';
  bool blocked = false, failGuide = false;
  int changes = 0;
  @override
  AuthSession get session => AuthSession(
    token: 'mode-$activeRole',
    userId: 3,
    fullName: 'Nguyễn Văn An',
    phoneNumber: '0900000003',
    role: activeRole,
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  @override
  Future<bool> availability() async => false;
  @override
  Future<List<Job>> contractorJobs() async => [];
  @override
  Future<List<JobApplication>> workerApplications() async => [];
  @override
  Future<List<WorkerProfile>> savedWorkers() async => [];
  @override
  Future<UserProfile> profile() async => UserProfile(
    id: 3,
    fullName: 'Nguyễn Văn An',
    phoneNumber: '0900000003',
    role: activeRole,
    verified: false,
    rating: 5,
    workerTier: activeRole == 'ROLE_WORKER' ? 'BRONZE' : null,
  );
  @override
  Future<TierGuide> tierGuide() async {
    if (failGuide) throw const ApiException('Mất kết nối cấp bậc');
    return TierGuide.fromJson(guideFixture);
  }

  @override
  Future<void> switchRole(String role) async {
    changes++;
    if (blocked) throw const ApiException('Bạn còn công việc đang xử lý.', 409);
    activeRole = role;
    notifyListeners();
  }
}

class _SettledWorkerApi extends RoleTierApi {
  @override
  Future<List<JobApplication>> workerApplications() async => [
    JobApplication(
      id: 9,
      job: chatJob,
      workerId: 3,
      workerName: 'Worker',
      workerPhone: '0900000003',
      workerActive: true,
      workerRating: 5,
      workerVerified: true,
      status: 'ACCEPTED',
    ),
  ];
}

void main() {
  test(
    'unreviewed default five stars do not count as earned tier progress',
    () {
      final silver = TierGuide.fromJson(guideFixture).tiers[1];
      const newWorker = UserProfile(
        id: 3,
        fullName: 'Worker',
        phoneNumber: '0900000003',
        role: 'ROLE_WORKER',
        verified: false,
        rating: 5,
      );
      expect(silver.progress(newWorker), closeTo(1 / 3, .0001));
    },
  );
  test('settled worker contact is resolved by participation after switching to contractor', () async {
    final api = _SettledWorkerApi()..activeRole = 'ROLE_CONTRACTOR';
    final contact = await loadChatContact(api, chatJob, 2);
    expect(contact?.phone, '0900000002');
    api.dispose();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> mount(
    WidgetTester tester,
    RoleTierApi api, {
    Widget? home,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(api.dispose);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: api,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.forRole(api.activeRole),
          home:
              home ??
              (api.activeRole == 'ROLE_WORKER'
                  ? WorkerHomeScreen(api: api)
                  : ContractorHomeScreen(api: api)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    final target = find.text(label).first;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'login has no role chooser while registration has two role cards',
    (tester) async {
      final api = RoleTierApi();
      await mount(tester, api, home: LoginScreen(api: api));
      expect(find.byType(RoleCards), findsNothing);
      expect(find.text('Tôi là thợ'), findsNothing);
      expect(find.text('Tôi là chủ thầu'), findsNothing);
      await tester.pumpWidget(MaterialApp(home: RegisterScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.byType(RoleCards), findsOneWidget);
      expect(find.text('Tôi là thợ'), findsOneWidget);
      expect(find.text('Tôi là chủ thầu'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'home tier badge opens four actual tiers, live progress and honest fee policy',
    (tester) async {
      final api = RoleTierApi();
      await mount(tester, api);
      await tester.tap(find.text('Bậc Đồng'));
      await tester.pumpAndSettle();
      expect(find.byType(TierDetailsScreen), findsOneWidget);
      expect(find.textContaining('Tiến trình lên Bạc:'), findsOneWidget);
      for (final label in [
        'Bậc Đồng',
        'Bậc Bạc',
        'Bậc Vàng',
        'Bậc Kim Cương',
      ]) {
        final badge = find.widgetWithText(TierBadge, label).last;
        await tester.scrollUntilVisible(
          badge,
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(badge, findsOneWidget);
      }
      await tester.scrollUntilVisible(
        find.text('Giảm phí theo bậc chưa áp dụng.'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Giảm phí theo bậc chưa áp dụng.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'profile badge also opens tier details without changing the active tab',
    (tester) async {
      final api = RoleTierApi();
      await mount(tester, api);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Hồ sơ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hành trình đến bậc Bạc'), findsOneWidget);
      await tapText(tester, 'Bậc Đồng');
      expect(find.byType(TierDetailsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'profile role switch confirms, can cancel, then changes shell and palette without logout',
    (tester) async {
      final api = RoleTierApi();
      await mount(tester, api);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Hồ sơ'),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Chuyển sang vai trò Chủ thầu');
      expect(api.changes, 0);
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(api.activeRole, 'ROLE_WORKER');
      await tapText(tester, 'Chuyển sang vai trò Chủ thầu');
      await tester.tap(find.text('Chuyển vai trò'));
      await tester.pumpAndSettle();
      expect(api.activeRole, 'ROLE_CONTRACTOR');
      expect(api.changes, 1);
      expect(api.logoutCount, 0);
      expect(find.byType(ContractorHomeScreen), findsOneWidget);
      expect(find.text('Đội thợ'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(NavigationBar)))
            .colorScheme
            .primary,
        AppTheme.contractorBlue,
      );
      expect(
        Navigator.of(tester.element(find.byType(ContractorHomeScreen)))
            .canPop(),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'blocked switch preserves role and exposes the real business reason in settings',
    (tester) async {
      final api = RoleTierApi()..blocked = true;
      await mount(tester, api, home: SettingsScreen(api: api));
      expect(find.byType(RoleSwitchTile), findsOneWidget);
      await tapText(tester, 'Chuyển sang vai trò Chủ thầu');
      await tester.tap(find.text('Chuyển vai trò'));
      await tester.pumpAndSettle();
      expect(api.activeRole, 'ROLE_WORKER');
      expect(find.text('Bạn còn công việc đang xử lý.'), findsOneWidget);
      expect(api.logoutCount, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('settings switch also returns contractor to worker mode', (
    tester,
  ) async {
    final api = RoleTierApi()..activeRole = 'ROLE_CONTRACTOR';
    await mount(tester, api);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Chuyển sang vai trò Thợ xây');
    await tester.tap(find.text('Chuyển vai trò'));
    await tester.pumpAndSettle();
    expect(api.activeRole, 'ROLE_WORKER');
    expect(find.byType(WorkerHomeScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).colorScheme.primary,
      AppTheme.workerAmber,
    );
    expect(api.session.userId, 3);
    expect(api.logoutCount, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'tier endpoint failure offers retry instead of invented rank data',
    (tester) async {
      final api = RoleTierApi()..failGuide = true;
      await mount(tester, api, home: TierDetailsScreen(api: api));
      expect(find.text('Mất kết nối cấp bậc'), findsOneWidget);
      api.failGuide = false;
      await tapText(tester, 'Thử lại');
      expect(find.text('Bậc hiện tại của bạn'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
