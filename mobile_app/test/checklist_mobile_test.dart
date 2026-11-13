import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/chat_message.dart';
import 'package:tho_xay_mobile/models/worker_profile.dart';
import 'package:tho_xay_mobile/models/app_notification.dart';
import 'package:tho_xay_mobile/models/portfolio_photo.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/screens/login_screen.dart';
import 'package:tho_xay_mobile/screens/chat_screen.dart';
import 'package:tho_xay_mobile/screens/profile_screen.dart';
import 'package:tho_xay_mobile/screens/wallet_screen.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/widgets/app_information.dart';
import 'package:tho_xay_mobile/widgets/brand_logo.dart';
import 'package:tho_xay_mobile/widgets/jobs_map.dart';
import 'package:tho_xay_mobile/widgets/profile_settings.dart';
import 'package:tho_xay_mobile/widgets/startup_gate.dart';

import 'wallet_test.dart' show WalletApi;
import 'maps_test.dart' show job, MemoryTiles, settleMap;
import 'support/fake_chat_api.dart';

class _ChecklistApi extends WalletApi {
  _ChecklistApi(this.role);
  final String role;
  int logins = 0;
  @override
  AuthSession get session => AuthSession(
    token: 'test',
    userId: role == 'ROLE_WORKER' ? 3 : 2,
    fullName: 'Trần Minh An',
    phoneNumber: '0900000003',
    role: role,
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  @override
  Future<void> login(String phoneNumber, String password) async {
    logins++;
  }

  @override
  Future<bool> availability() async => false;
  @override
  Future<List<JobApplication>> workerApplications() async => [];
  @override
  Future<List<Job>> contractorJobs() async => [];
  @override
  Future<List<WorkerProfile>> savedWorkers() async => [];
  @override
  Future<List<PortfolioPhoto>> portfolio(int userId) async => [];
  @override
  Future<UserProfile> profile() async => UserProfile(
    id: session.userId,
    fullName: session.fullName,
    phoneNumber: session.phoneNumber,
    role: role,
    verified: true,
    rating: 5,
  );
  @override
  Future<int> unreadMessages() async => 3;
  @override
  Future<NotificationPage> notifications({int? beforeId}) async =>
      const NotificationPage([], false, 2);
}

class _StackObserver extends NavigatorObserver {
  final routes = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = routes.indexOf(oldRoute!);
    if (i >= 0) routes[i] = newRoute!;
  }
}

void main() {
  test('role palette and readable foregrounds match the requested helmet/engineer brand', () {
    expect(AppTheme.workerAmber, const Color(0xFFD97706));
    expect(AppTheme.contractorBlue, const Color(0xFF1D4ED8));
    for (final role in ['ROLE_WORKER', 'ROLE_CONTRACTOR']) {
      for (final brightness in Brightness.values) {
        final theme = AppTheme.forRole(role, brightness: brightness);
        final colors = theme.colorScheme;
        final a = colors.primary.computeLuminance(),
            b = colors.onPrimary.computeLuminance();
        expect(
          (math.max(a, b) + .05) / (math.min(a, b) + .05),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  testWidgets(
    'brand is a transparent vector helmet without a wordmark image or text',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BrandLogo(height: 80, onDark: true)),
        ),
      );
      final logo = find.byType(BrandLogo);
      expect(
        find.descendant(of: logo, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        find.descendant(of: logo, matching: find.byType(Text)),
        findsNothing,
      );
      expect(
        find.descendant(of: logo, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
      expect(tester.getSize(logo), const Size(128, 80));
      expect(find.bySemanticsLabel('Thợ Xây · Mũ bảo hộ'), findsOneWidget);
    },
  );

  testWidgets(
    'startup finishes on real readiness without decorative wait and fades to content',
    (tester) async {
      final ready = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: StartupGate(
            initialize: () => ready.future,
            builder: (_) => const Text('Nội dung thật'),
          ),
        ),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      await tester.pump(const Duration(milliseconds: 30));
      ready.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Nội dung thật'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.byType(SplashScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final role in ['ROLE_WORKER', 'ROLE_CONTRACTOR']) {
    testWidgets(
      'core tabs persist and replace instead of stacking routes: $role',
      (tester) async {
        final api = _ChecklistApi(role), observer = _StackObserver();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.forRole(role),
            navigatorObservers: [observer],
            home: role == 'ROLE_WORKER'
                ? WorkerHomeScreen(api: api)
                : ContractorHomeScreen(api: api),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('Ví tiền'));
          await tester.pumpAndSettle();
          expect(find.byType(WalletScreen), findsOneWidget);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            2,
          );
          expect(observer.routes.length, 2);
          await tester.tap(find.text('Hồ sơ'));
          await tester.pumpAndSettle();
          expect(find.byType(ProfileScreen), findsOneWidget);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            3,
          );
          expect(observer.routes.length, 2);
        }
        await tester.tap(
          find.text(role == 'ROLE_WORKER' ? 'Việc của tôi' : 'Đội thợ'),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        expect(observer.routes.length, role == 'ROLE_WORKER' ? 1 : 2);
        await tester.tap(
          find.text(role == 'ROLE_WORKER' ? 'Tìm việc' : 'Công trình'),
        );
        await tester.pumpAndSettle();
        expect(observer.routes.length, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }

  testWidgets(
    'password help is honest and never submits credentials or fakes a reset',
    (tester) async {
      final api = _ChecklistApi('ROLE_WORKER');
      await tester.pumpWidget(MaterialApp(home: LoginScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('chưa hỗ trợ đặt lại mật khẩu tự động'),
        findsOneWidget,
      );
      expect(api.logins, 0);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  test('settings release metadata defaults match the actual pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: ${AppRelease.label}'));
  });

  testWidgets('settings expose version and truthful data explanation', (
    tester,
  ) async {
    final api = _ChecklistApi('ROLE_WORKER');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ProfileSettings(api: api)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Thợ Xây · Phiên bản ${AppRelease.label}'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Quyền truy cập & dữ liệu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quyền truy cập & dữ liệu'));
    await tester.pumpAndSettle();
    expect(find.textContaining('không thay thế chính sách'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'overlapping map pins remain independently selectable through a cluster sheet',
    (tester) async {
      final first = job(1, 10.779, 106.705), second = job(2, 10.779, 106.705);
      Job? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: JobsMap(
                center: const GeoPoint(10.7769, 106.7009),
                jobs: [first, second],
                tileProvider: MemoryTiles(),
                onJobTap: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await settleMap(tester);
      expect(find.byKey(const ValueKey('job-cluster-1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('job-cluster-1')));
      await settleMap(tester);
      expect(find.text('2 công trình gần nhau'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, second.title));
      await settleMap(tester);
      expect(selected?.id, 2);
      expect(find.text('OpenStreetMap contributors'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'recenter map control returns camera to the actual search center',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: JobsMap(
                center: const GeoPoint(10.7769, 106.7009),
                jobs: [],
                tileProvider: MemoryTiles(),
                onJobTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await settleMap(tester);
      await tester.drag(find.byType(JobsMap), const Offset(70, 80));
      await settleMap(tester);
      await tester.tap(find.byTooltip('Về vị trí đang dùng'));
      await settleMap(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'long press copies text and swipe reply preserves draft without sending',
    (tester) async {
      final api = FakeChatApi()
        ..rows.add(message(1, content: 'Kiểm tra nghiệm thu'));
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(api: api, job: chatJob, peerId: 2, peerName: 'Minh'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Kiểm tra nghiệm thu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sao chép'));
      await tester.pumpAndSettle();
      expect(copied, 'Kiểm tra nghiệm thu');
      await tester.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Bản nháp của tôi',
      );
      await tester.pump();
      await tester.fling(
        find.text('Kiểm tra nghiệm thu'),
        const Offset(120, 0),
        700,
      );
      await tester.pumpAndSettle();
      final draft = tester
          .widget<TextField>(find.byKey(const ValueKey('chat-input')))
          .controller!
          .text;
      expect(draft, '> Kiểm tra nghiệm thu\nBản nháp của tôi');
      expect(api.sentIds, isEmpty);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'jump to new messages keeps read cursor at the last visible message',
    (tester) async {
      final api = FakeChatApi();
      final history = List.generate(40, (i) => message(i + 1));
      api.rows.addAll(history);
      api.initialHistory = Completer<MessagePage>()
        ..complete(MessagePage(history, false));
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(api: api, job: chatJob, peerId: 2, peerName: 'Minh'),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey('chat-messages')),
          matching: find.byType(Scrollable),
        ),
      );
      scroll.position.jumpTo(400);
      await tester.pumpAndSettle();
      final incoming = message(41);
      api.rows.add(incoming);
      api.connections.last.add(messageEvent(incoming));
      await tester.pumpAndSettle();
      expect(api.readIds.last, 40);
      expect(find.text('1 tin mới'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-scroll-latest')));
      await tester.pumpAndSettle();
      expect(api.readIds.last, 41);
      expect(find.byKey(const ValueKey('chat-scroll-latest')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets('mobile chat composer rises above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final api = FakeChatApi()..rows.add(message(1));
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(api: api, job: chatJob, peerId: 2, peerName: 'Minh'),
      ),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('chat-input'))).bottom,
      lessThanOrEqualTo(544),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
