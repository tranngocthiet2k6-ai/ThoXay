import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/auth_screen.dart';
import 'package:tho_xay_mobile/screens/login_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/appearance_button.dart';
import 'package:tho_xay_mobile/widgets/auth_forms.dart';
import 'package:tho_xay_mobile/widgets/auth_shell.dart';
import 'package:tho_xay_mobile/widgets/brand_logo.dart';

class _AuthApi extends ApiService {
  final logins = <({String phone, String password})>[];
  final registrations =
      <({String name, String phone, String password, String role})>[];
  Completer<void>? loginWait, registerWait;
  bool rejectLogin = false;

  @override
  Future<void> login(String phoneNumber, String password) async {
    logins.add((phone: phoneNumber, password: password));
    await loginWait?.future;
    if (rejectLogin) throw const ApiException('Sai thông tin đăng nhập', 401);
  }

  @override
  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String role,
    String? cccdFrontImage,
    String? cccdBackImage,
  }) async {
    registrations.add((
      name: fullName,
      phone: phoneNumber,
      password: password,
      role: role,
    ));
    await registerWait?.future;
  }
}

class _Routes extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

void main() {
  Finder tab(String text) =>
      find.descendant(of: find.byType(AuthTabs), matching: find.text(text));
  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Future<void> choose(WidgetTester tester, String text) async {
    await tester.tap(tab(text));
    await tester.pumpAndSettle();
  }

  Future<void> fillRegistration(WidgetTester tester) async {
    for (final entry in [
      ('Họ và tên', 'Trần Ngọc Thiết'),
      ('Số điện thoại', '0900000003'),
      ('Mật khẩu', 'password123'),
      ('Nhập lại mật khẩu', 'password123'),
    ]) {
      await tester.ensureVisible(field(entry.$1));
      await tester.enterText(field(entry.$1), entry.$2);
    }
  }

  testWidgets(
    'footer switches tabs without a route and the header never moves',
    (tester) async {
      final api = _AuthApi(), routes = _Routes();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routes],
          home: LoginScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();
      final logo = tester.element(find.byType(BrandLogo));
      final logoPosition = tester.getTopLeft(find.byType(BrandLogo));
      final tabsPosition = tester.getTopLeft(find.byType(AuthTabs));
      final pushes = routes.pushes;
      await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterForm), findsOneWidget);
      expect(routes.pushes, pushes);
      expect(identical(tester.element(find.byType(BrandLogo)), logo), isTrue);
      expect(tester.getTopLeft(find.byType(BrandLogo)), logoPosition);
      expect(tester.getTopLeft(find.byType(AuthTabs)), tabsPosition);
      expect(find.byType(AppearanceButton), findsOneWidget);
      expect(find.text('Quay lại đăng nhập'), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(AuthScreen))).canPop(),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets('indicator slides and forms enter from opposite sides', (
    tester,
  ) async {
    final api = _AuthApi();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(api: api)));
    await tester.pumpAndSettle();
    final indicator = find.descendant(
      of: find.byKey(const ValueKey('auth-tab-indicator')),
      matching: find.byType(FractionallySizedBox),
    );
    final left = tester.getTopLeft(indicator).dx;
    final indicatorWidth = tester.getSize(indicator).width;
    await tester.tap(tab('Đăng ký'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final alignment = tester.widget<AnimatedAlign>(
      find.byKey(const ValueKey('auth-tab-indicator')),
    );
    expect(alignment.duration, const Duration(milliseconds: 250));
    expect(alignment.curve, Curves.easeOutCubic);
    expect(tester.getTopLeft(indicator).dx, greaterThan(left));
    expect(tester.getTopLeft(indicator).dx, lessThan(left + indicatorWidth));
    SlideTransition slide(String title) => tester.widget<SlideTransition>(
      find
          .ancestor(
            of: find.text(title),
            matching: find.byType(SlideTransition),
          )
          .first,
    );
    expect(slide('Bắt đầu kết nối').position.value.dx, greaterThan(0));
    expect(
      slide('Vững tay nghề. Vững tương lai.').position.value.dx,
      lessThan(0),
    );
    await tester.pumpAndSettle();
    await tester.tap(tab('Đăng nhập'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      slide('Vững tay nghề. Vững tương lai.').position.value.dx,
      lessThan(0),
    );
    expect(slide('Bắt đầu kết nối').position.value.dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'drafts and role survive rapid switches and keyboard loses focus',
    (tester) async {
      final api = _AuthApi();
      await tester.pumpWidget(MaterialApp(home: AuthScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.enterText(field('Số điện thoại'), '0900000003');
      final phoneFocus = tester
          .widget<EditableText>(
            find.descendant(
              of: field('Số điện thoại'),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode;
      expect(phoneFocus.hasFocus, isTrue);
      await choose(tester, 'Đăng ký');
      expect(phoneFocus.hasFocus, isFalse);
      await tester.tap(find.text('Tôi là chủ thầu'));
      await tester.enterText(field('Họ và tên'), 'Trần Văn Anh Vũ');
      await tester.tap(tab('Đăng nhập'));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(tab('Đăng ký'));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(tab('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(field('Số điện thoại')).controller!.text,
        '0900000003',
      );
      await choose(tester, 'Đăng ký');
      expect(
        tester.widget<TextFormField>(field('Họ và tên')).controller!.text,
        'Trần Văn Anh Vũ',
      );
      expect(
        tester.widget<RegisterForm>(find.byType(RegisterForm)).role,
        'ROLE_CONTRACTOR',
      );
      expect(tester.takeException(), isNull);
      expect(api.logins, isEmpty);
      expect(api.registrations, isEmpty);
      expect(
        tester.testTextInput.log.where(
          (call) =>
              call.method == 'TextInput.finishAutofillContext' &&
              call.arguments == true,
        ),
        isEmpty,
        reason: 'Switching tabs must not commit unfinished login credentials.',
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets('login busy guard prevents tab changes and duplicate requests', (
    tester,
  ) async {
    final api = _AuthApi()
      ..loginWait = Completer<void>()
      ..rejectLogin = true;
    await tester.pumpWidget(MaterialApp(home: AuthScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.enterText(field('Số điện thoại'), '0900000003');
    await tester.enterText(field('Mật khẩu'), 'password123');
    final submit = find.byType(FilledButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(tab('Đăng ký'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<AuthTabs>(find.byType(AuthTabs)).selected, 0);
    expect(api.logins, [(phone: '0900000003', password: 'password123')]);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    api.loginWait!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Sai thông tin đăng nhập'), findsOneWidget);
    await choose(tester, 'Đăng ký');
    expect(find.byType(RegisterForm), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'initial register tab submits the same role and registration fields',
    (tester) async {
      final api = _AuthApi()..registerWait = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(home: AuthScreen(api: api, initialTab: 1)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi là chủ thầu'));
      await fillRegistration(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tạo tài khoản'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo tài khoản'));
      await tester.pump();
      await tester.tap(tab('Đăng nhập'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<AuthTabs>(find.byType(AuthTabs)).selected, 1);
      expect(api.registrations, [
        (
          name: 'Trần Ngọc Thiết',
          phone: '0900000003',
          password: 'password123',
          role: 'ROLE_CONTRACTOR',
        ),
      ]);
      api.registerWait!.complete();
      await tester.pumpAndSettle();
      await choose(tester, 'Đăng nhập');
      expect(find.byType(LoginForm), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  for (final size in [const Size(360, 800), const Size(390, 844)]) {
    for (final brightness in Brightness.values) {
      testWidgets('auth scrolls with keyboard at $size $brightness', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final api = _AuthApi();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.forRole(null, brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: AuthScreen(api: api),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
        await choose(tester, 'Đăng ký');
        await tester.ensureVisible(find.text('Tạo tài khoản'));
        await tester.pumpAndSettle();
        expect(find.text('Tạo tài khoản').hitTestable(), findsOneWidget);
        expect(find.byType(BrandLogo).hitTestable(), findsOneWidget);
        expect(find.byType(AuthTabs).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      });
    }
  }

  testWidgets('reduced motion switches without leaving an animated old form', (
    tester,
  ) async {
    final api = _AuthApi();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: AuthScreen(api: api),
      ),
    );
    await tester.pumpAndSettle();
    await choose(tester, 'Đăng ký');
    expect(
      tester
          .widget<AnimatedAlign>(
            find.byKey(const ValueKey('auth-tab-indicator')),
          )
          .duration,
      Duration.zero,
    );
    expect(find.byType(LoginForm), findsNothing);
    expect(find.byType(RegisterForm), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
