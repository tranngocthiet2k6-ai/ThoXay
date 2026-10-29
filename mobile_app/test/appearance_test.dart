import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/main.dart';
import 'package:tho_xay_mobile/screens/register_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/theme/appearance_controller.dart';

double _contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);
void main() {
  testWidgets(
    'registration previews role colors while retaining dark and outdoor display modes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppearanceController();
      await controller.setMode(DisplayMode.dark);
      final api = ApiService();
      await tester.pumpWidget(ThoXayApp(api: api, appearance: controller));
      await tester.pumpAndSettle();
      final root = tester.element(find.byType(Scaffold).first);
      Navigator.of(
        root,
      ).push(MaterialPageRoute<void>(builder: (_) => RegisterScreen(api: api)));
      await tester.pumpAndSettle();
      ThemeData registrationTheme() =>
          Theme.of(tester.element(find.text('Bắt đầu kết nối')));
      expect(registrationTheme().brightness, Brightness.dark);
      await tester.ensureVisible(find.text('Tôi là chủ thầu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi là chủ thầu'));
      await tester.pumpAndSettle();
      expect(
        registrationTheme().colorScheme.primary,
        AppTheme.contractorEmerald,
      );
      expect(registrationTheme().brightness, Brightness.dark);
      await controller.setMode(DisplayMode.outdoor);
      await tester.pumpAndSettle();
      expect(registrationTheme().extension<AppPalette>()!.outdoor, isTrue);
      expect(
        registrationTheme().colorScheme.primary,
        AppTheme.contractorEmerald,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      api.dispose();
    },
  );
  test('all display modes preserve role colors and readable semantic text', () {
    for (final role in ['ROLE_WORKER', 'ROLE_CONTRACTOR']) {
      for (final mode in DisplayMode.values) {
        final theme = AppTheme.forRole(
          role,
          brightness: mode == DisplayMode.dark
              ? Brightness.dark
              : Brightness.light,
          outdoor: mode == DisplayMode.outdoor,
        );
        final palette = theme.extension<AppPalette>()!;
        expect(theme.chipTheme.labelStyle!.color, palette.ink);
        expect(
          theme.navigationBarTheme.labelTextStyle!.resolve({})!.color,
          palette.ink,
        );
        expect(
          theme.colorScheme.primary,
          role == 'ROLE_WORKER'
              ? AppTheme.workerOrange
              : AppTheme.contractorEmerald,
        );
        expect(
          _contrast(palette.ink, palette.surface),
          greaterThanOrEqualTo(7),
        );
        expect(
          _contrast(palette.muted, palette.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(palette.successStrong, palette.successSoft),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(palette.warning, palette.warningSoft),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(palette.errorStrong, palette.errorSoft),
          greaterThanOrEqualTo(4.5),
        );
        if (mode == DisplayMode.outdoor) {
          expect(
            theme.filledButtonTheme.style!.foregroundColor!.resolve({}),
            Colors.white,
          );
          expect(
            theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
            Colors.black,
          );
          expect(
            (theme.cardTheme.shape! as RoundedRectangleBorder).side.width,
            2,
          );
        }
      }
    }
  });
  test(
    'appearance is persisted and the latest quick selection wins after restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppearanceController();
      await controller.restore();
      expect(controller.mode, DisplayMode.light);
      await Future.wait([
        controller.setMode(DisplayMode.dark),
        controller.setMode(DisplayMode.outdoor),
      ]);
      final restored = AppearanceController();
      await restored.restore();
      expect(restored.mode, DisplayMode.outdoor);
      expect(restored.brightness, Brightness.light);
      controller.dispose();
      restored.dispose();
    },
  );
  testWidgets(
    'selector changes login and an already open route without restarting or logging out',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppearanceController();
      final api = ApiService();
      await tester.pumpWidget(ThoXayApp(api: api, appearance: controller));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Giao diện hiển thị'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Giao diện hiển thị'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('Tối'),
          matching: find.byType(CheckedPopupMenuItem<DisplayMode>),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.mode, DisplayMode.dark);
      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).brightness, Brightness.dark);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Trang đang mở')),
        ),
      );
      await tester.pumpAndSettle();
      await controller.setMode(DisplayMode.outdoor);
      await tester.pumpAndSettle();
      final next = Theme.of(tester.element(find.text('Trang đang mở')));
      expect(next.extension<AppPalette>()!.outdoor, isTrue);
      expect(next.scaffoldBackgroundColor, Colors.white);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      api.dispose();
    },
  );
}
