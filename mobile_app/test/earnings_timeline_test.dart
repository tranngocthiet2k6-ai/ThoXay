import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/wallet.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/earnings_timeline_chart.dart';

EarningsDay _day(int date, int amount) => EarningsDay.fromJson({
  'date': '2026-10-${date.toString().padLeft(2, '0')}',
  'base': amount,
  'tip': 0,
  'bonus': 0,
  'total': amount,
});
void main() {
  testWidgets(
    'daily bars use exact amounts and zero income is a zero height bar',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: EarningsTimelineChart(
              days: [_day(1, 600000), _day(2, 0), _day(3, 300000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = tester
          .getSize(find.byKey(const ValueKey('earnings-day-2026-10-01')))
          .height;
      final zero = tester
          .getSize(find.byKey(const ValueKey('earnings-day-2026-10-02')))
          .height;
      final half = tester
          .getSize(find.byKey(const ValueKey('earnings-day-2026-10-03')))
          .height;
      expect(zero, 0);
      expect(first, greaterThan(0));
      expect(half, closeTo(first / 2, .01));
      expect(find.text('Theo ngày thanh toán · Giờ Việt Nam'), findsOneWidget);
    },
  );
  testWidgets(
    'month chart scrolls horizontally on a phone without clipping the last day',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_WORKER', brightness: Brightness.dark),
          home: Scaffold(
            body: EarningsTimelineChart(
              days: List.generate(31, (i) => _day(i + 1, i * 10000)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('31/10'));
      await tester.pumpAndSettle();
      expect(find.text('31/10').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('old aggregate-only response never fabricates daily amounts', (
    tester,
  ) async {
    final old = Earnings.fromJson({
      'base': 600000,
      'tip': 0,
      'bonus': 0,
      'total': 600000,
      'settledJobs': 1,
      'from': '2026-10-01',
      'toExclusive': '2026-11-01',
    });
    expect(old.days, isEmpty);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EarningsTimelineChart(days: old.days)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Máy chủ chưa trả chi tiết từng ngày'),
      findsOneWidget,
    );
  });
}
