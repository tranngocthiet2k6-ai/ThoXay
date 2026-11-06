import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/main.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/screens/login_screen.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/theme/appearance_controller.dart';
import 'package:tho_xay_mobile/widgets/brand_logo.dart';
import 'package:tho_xay_mobile/widgets/startup_gate.dart';

class _StartupApi extends ApiService {
  @override
  Future<bool> availability() async => false;
  @override
  Future<List<JobApplication>> workerApplications() async => [];
  @override
  Future<List<Job>> contractorJobs() async => [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('splash fades in and waits 1.5 seconds before showing login', (
    tester,
  ) async {
    final api = ApiService();
    await tester.pumpWidget(
      ThoXayApp(api: api, splashDuration: const Duration(milliseconds: 1500)),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.text('Kết nối tay nghề, dựng xây uy tín'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    Opacity opacity() => tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(SplashScreen),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity().opacity, 0);
    await tester.pump(const Duration(milliseconds: 275));
    expect(opacity().opacity, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 1224));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets('default widget tests skip splash timing automatically', (
    tester,
  ) async {
    final api = ApiService();
    await tester.pumpWidget(ThoXayApp(api: api));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets('slow startup never flashes login and announces readiness once', (
    tester,
  ) async {
    final ready = Completer<void>();
    var callbacks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate(
          minimumDuration: const Duration(milliseconds: 1500),
          initialize: () => ready.future,
          onReady: () => callbacks++,
          builder: (_) => const Text('Trang chính'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Trang chính'), findsNothing);
    ready.complete();
    await tester.pumpAndSettle();
    expect(find.text('Trang chính'), findsOneWidget);
    expect(callbacks, 1);
    await tester.pump();
    expect(callbacks, 1);
  });

  for (final role in ['ROLE_WORKER', 'ROLE_CONTRACTOR']) {
    testWidgets('restored $role opens its home after startup', (tester) async {
      final saved = AuthSession(
        token: 'test-token',
        userId: 3,
        fullName: 'Người dùng',
        phoneNumber: '0900000003',
        role: role,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      SharedPreferences.setMockInitialValues({
        'thoxay.session': jsonEncode(saved.toJson()),
      });
      final api = _StartupApi();
      await tester.pumpWidget(
        ThoXayApp(api: api, initialize: api.restoreSession),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsNothing);
      expect(
        find.byType(
          role == 'ROLE_WORKER' ? WorkerHomeScreen : ContractorHomeScreen,
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }

  testWidgets('restored appearance applies while splash is visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'display_mode': 'dark'});
    final api = ApiService();
    final appearance = AppearanceController();
    await tester.pumpWidget(
      ThoXayApp(
        api: api,
        appearance: appearance,
        initialize: appearance.restore,
        splashDuration: const Duration(milliseconds: 1500),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      Theme.of(tester.element(find.byType(SplashScreen))).brightness,
      Brightness.dark,
    );
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
    api.dispose();
  });

  testWidgets('startup failure can retry and disposal cancels the delay', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate(
          initialize: () async {
            if (++attempts == 1) throw StateError('Storage unavailable');
          },
          builder: (_) => const Text('Sẵn sàng'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Sẵn sàng'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate(
          key: const ValueKey('dispose-during-startup'),
          minimumDuration: const Duration(milliseconds: 1500),
          builder: (_) => const Text('Không được mở'),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
