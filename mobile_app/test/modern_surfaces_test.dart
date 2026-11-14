import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/wallet.dart';
import 'package:tho_xay_mobile/screens/login_screen.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/theme/appearance_controller.dart';
import 'package:tho_xay_mobile/widgets/commercial_hero.dart';
import 'package:tho_xay_mobile/widgets/dashboard_stats.dart';
import 'package:tho_xay_mobile/widgets/hero_greeting.dart';
import 'package:tho_xay_mobile/widgets/modern_controls.dart';
import 'package:tho_xay_mobile/widgets/profile_settings.dart';
import 'package:tho_xay_mobile/widgets/profile_summary.dart';
import 'package:tho_xay_mobile/widgets/wallet_surfaces.dart';

import 'wallet_test.dart' show WalletApi;
import 'support/fake_chat_api.dart' show chatJob;

class _UiApi extends WalletApi {
  _UiApi(this.role);
  final String role;
  bool logoutCalled = false;
  @override
  AuthSession? get session => AuthSession(
    token: 'qa',
    userId: 3,
    fullName: 'Trần Minh An',
    phoneNumber: '0900000003',
    role: role,
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  @override
  Future<UserProfile> profile() async => UserProfile(
    id: 3,
    fullName: 'Trần Minh An',
    phoneNumber: '0900000003',
    role: role,
    verified: true,
    rating: 4.8,
    reputationScore: 92,
    completedJobs: 12,
    workerTier: 'GOLD',
  );
  @override
  Future<bool> availability() async => false;
  @override
  Future<List<JobApplication>> workerApplications() async => [
    for (final status in ['ACCEPTED', 'PENDING', 'CANCELLED'])
      JobApplication(
        id: status.hashCode,
        job: chatJob,
        workerId: 3,
        workerName: 'An',
        workerPhone: '0900000003',
        workerRating: 5,
        workerVerified: true,
        workerActive: true,
        status: status,
      ),
  ];
  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 840.0, 1440.0]) {
    for (final mode in [
      DisplayMode.light,
      DisplayMode.dark,
      DisplayMode.outdoor,
    ]) {
      testWidgets('polished surfaces fit width=$width mode=$mode', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = _UiApi('ROLE_WORKER');
        final theme = AppTheme.forRole(
          'ROLE_WORKER',
          brightness: mode == DisplayMode.dark
              ? Brightness.dark
              : Brightness.light,
          outdoor: mode == DisplayMode.outdoor,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      HeroGreeting(
                        api: api,
                        title: 'Tìm công trình',
                        subtitle: 'Việc gần bạn',
                        availability: true,
                        onAvailabilityChanged: (_) {},
                      ),
                      const DashboardStats(
                        values: [
                          (value: '12', label: 'Đang tuyển'),
                          (value: '8', label: 'Đang thực hiện'),
                          (value: '24', label: 'Hoàn thành'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const ProfileSummary(
                        name: 'Trần Minh An',
                        phone: '0900000003',
                        worker: true,
                        rating: 4.8,
                        score: 92,
                        completed: 12,
                        tier: 'GOLD',
                        verified: true,
                      ),
                      const SizedBox(height: 16),
                      CommercialHero(
                        child: WalletCompartments(
                          balance: WalletBalance.fromJson({
                            'mainBalance': 12500000,
                            'escrowBalance': 200000,
                            'heldBalance': 500000,
                            'minimumEscrow': 200000,
                            'lowEscrow': false,
                          }),
                          hidden: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final hero = find.byType(HeroGreeting);
        expect(
          find.descendant(of: hero, matching: find.byType(CommercialHero)),
          findsNothing,
        );
        expect(tester.getSize(hero).height, lessThan(190));
        expect(find.text('Chào An!'), findsOneWidget);
        expect(find.byType(GradientProgress), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      });
    }
  }

  testWidgets('login cards animate selection and focus follows role accent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final api = _UiApi('ROLE_WORKER');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(api: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tôi là chủ thầu'));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextFormField, 'Số điện thoại');
    final theme = Theme.of(tester.element(field));
    expect(theme.colorScheme.primary, AppTheme.contractorEmerald);
    expect(
      (theme.inputDecorationTheme.prefixIconColor! as WidgetStateColor).resolve(
        {WidgetState.focused},
      ),
      AppTheme.contractorEmerald,
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập số điện thoại hợp lệ'), findsOneWidget);
    expect(
      calls.where((c) => c.method == 'HapticFeedback.vibrate'),
      hasLength(2),
    );
    final button = find.byType(GradientPrimaryButton);
    expect(tester.getSize(button).height, 52);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'grouped appearance settings persist dark/outdoor modes and logout',
    (tester) async {
      final api = _UiApi('ROLE_WORKER');
      final appearance = AppearanceController();
      await tester.pumpWidget(
        AppearanceScope(
          controller: appearance,
          child: ListenableBuilder(
            listenable: appearance,
            builder: (_, _) => MaterialApp(
              theme: AppTheme.forRole(
                'ROLE_WORKER',
                brightness: appearance.brightness,
                outdoor: appearance.mode == DisplayMode.outdoor,
              ),
              home: Scaffold(
                body: SingleChildScrollView(child: ProfileSettings(api: api)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao diện Sáng / Tối'));
      await tester.pumpAndSettle();
      expect(appearance.mode, DisplayMode.dark);
      await tester.tap(find.text('Tương phản cao (Ngoài trời)'));
      await tester.pumpAndSettle();
      expect(appearance.mode, DisplayMode.outdoor);
      final restored = AppearanceController();
      await restored.restore();
      expect(restored.mode, DisplayMode.outdoor);
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(api.logoutCalled, isFalse);
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
      await tester.pumpAndSettle();
      expect(api.logoutCalled, isTrue);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
      restored.dispose();
      api.dispose();
    },
  );

  testWidgets(
    'transaction opens actual reference and hides no financial actions',
    (tester) async {
      final entry = WalletEntry.fromJson({
        'id': 42,
        'kind': 'TOP_UP',
        'amount': 450000,
        'description': 'Đối soát nạp tiền',
        'createdAt': '2026-11-10T02:30:00Z',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WalletTransactionTile(entry: entry)),
        ),
      );
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.text('Mã tham chiếu: #42'), findsOneWidget);
      expect(find.text('Đối soát nạp tiền'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'work status pills filter actual applications without changing API state',
    (tester) async {
      final api = _UiApi('ROLE_WORKER');
      await tester.pumpWidget(MaterialApp(home: WorkerHomeScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Việc của tôi'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PillTabs), findsOneWidget);
      await tester.ensureVisible(find.byType(PillTabs));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chờ duyệt'));
      await tester.pumpAndSettle();
      expect(tester.widget<PillTabs>(find.byType(PillTabs)).selected, 1);
      await tester.tap(find.text('Hoàn thành'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có việc ở trạng thái này'), findsOneWidget);
      await tester.ensureVisible(find.text('Xem tất cả việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem tất cả việc'));
      await tester.pumpAndSettle();
      expect(tester.widget<PillTabs>(find.byType(PillTabs)).selected, 3);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'radar discovery settles and reduced motion has no ongoing ticker',
    (tester) async {
      for (final reduced in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: const Scaffold(
                body: Center(child: RadarPulse(child: Icon(Icons.location_on))),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('gradient progress paints a real fill at the correct fraction', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 200, child: GradientProgress(value: .75)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fraction = find.byType(FractionallySizedBox);
    expect(tester.getSize(fraction).width, 150);
    expect(tester.getSize(fraction).height, 6);
    expect(tester.widget<FractionallySizedBox>(fraction).heightFactor, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
