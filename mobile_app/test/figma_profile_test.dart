import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/profile_screen.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';

import 'role_tier_ui_test.dart' show RoleTierApi;

void main() {
  for (final worker in [true, false]) {
    testWidgets(
      'profile has 3 by 2 utilities with direct main-tab actions worker=$worker',
      (tester) async {
        final api = RoleTierApi()
          ..activeRole = worker ? 'ROLE_WORKER' : 'ROLE_CONTRACTOR';
        var tab = -1;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.forRole(api.activeRole),
            home: ProfileScreen(
              api: api,
              embedded: true,
              onNavigateTab: (index) => tab = index,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final names = [
          'Tay nghề',
          'Chứng chỉ',
          'Đã lưu',
          'Ngân hàng',
          'Trợ giúp',
          'Cài đặt',
        ];
        final positions = names
            .map((name) => tester.getCenter(find.text(name)))
            .toList();
        expect(positions[0].dy, positions[1].dy);
        expect(positions[1].dy, positions[2].dy);
        expect(positions[3].dy, positions[4].dy);
        expect(positions[4].dy, positions[5].dy);
        expect(positions[0].dx, lessThan(positions[1].dx));
        expect(positions[1].dx, lessThan(positions[2].dx));
        await tester.ensureVisible(find.text('Ngân hàng'));
        await tester.tap(find.text('Ngân hàng'));
        expect(tab, 3);
        if (!worker) {
          await tester.ensureVisible(find.text('Đã lưu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Đã lưu'));
          expect(tab, 1);
        }
        expect(
          Navigator.of(tester.element(find.byType(ProfileScreen))).canPop(),
          isFalse,
        );
        expect(
          find.byTooltip(
            'Chưa có thống kê tỷ lệ đúng giờ từ hệ thống chấm công.',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }
}
