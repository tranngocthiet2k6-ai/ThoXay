import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/login_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/design_motion.dart';

void main() {
  testWidgets('job collections use two desktop columns and one mobile column', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [390.0, 1100.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveJobGrid(
              children: [
                SizedBox(key: ValueKey('first-job'), height: 100),
                SizedBox(key: ValueKey('second-job'), height: 100),
              ],
            ),
          ),
        ),
      );
      final first = tester.getRect(find.byKey(const ValueKey('first-job')));
      final second = tester.getRect(find.byKey(const ValueKey('second-job')));
      if (width > 800) {
        expect(second.top, first.top);
        expect(second.left, greaterThan(first.right));
      } else {
        expect(second.top, greaterThanOrEqualTo(first.bottom));
        expect(first.width, width);
      }
      expect(tester.takeException(), isNull);
    }
  });
  for (final width in [320.0, 1440.0]) {
    testWidgets('auth remains usable at $width with larger text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: LoginScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đăng nhập'));
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập số điện thoại hợp lệ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }

  testWidgets('scroll reveals content and reduced motion skips animation', (
    tester,
  ) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: const Column(
              children: [
                SizedBox(height: 1000),
                DesignReveal(child: Text('Revealed section')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Opacity opacity() => tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(DesignReveal),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity().opacity, 0);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(opacity().opacity, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const DesignReveal(child: Text('No animation')),
        ),
      ),
    );
    await tester.pump();
    expect(opacity().opacity, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
