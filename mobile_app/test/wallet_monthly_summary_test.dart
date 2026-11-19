import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/wallet.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/wallet_monthly_summary.dart';

class _MonthlyApi extends ApiService {
  final dates = <DateTime>[];
  @override
  Future<Earnings> earnings(String period, DateTime date) async {
    expect(period, 'MONTH');
    dates.add(date);
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final current = date.year == now.year && date.month == now.month;
    return Earnings.fromJson({
      'base': current ? 300000 : 200000,
      'tip': 0,
      'bonus': 0,
      'total': current ? 300000 : 200000,
      'settledJobs': 1,
      'from': '${date.year}-${date.month.toString().padLeft(2, '0')}-01',
      'toExclusive': DateTime(date.year, date.month + 1).toIso8601String(),
    });
  }
}

void main() {
  testWidgets(
    'monthly summary compares server totals and respects balance privacy',
    (tester) async {
      final api = _MonthlyApi();
      Widget screen(bool hidden) => MaterialApp(
        home: Scaffold(
          body: WalletMonthlySummary(
            api: api,
            entries: const [],
            hasMore: false,
            hidden: hidden,
          ),
        ),
      );
      await tester.pumpWidget(screen(false));
      await tester.pumpAndSettle();
      expect(api.dates, hasLength(2));
      expect(find.text('300.000 đ'), findsOneWidget);
      expect(find.text('↗ +50%'), findsOneWidget);
      await tester.pumpWidget(screen(true));
      await tester.pumpAndSettle();
      expect(find.text('300.000 đ'), findsNothing);
      expect(find.text('↗ +50%'), findsNothing);
      expect(find.text('••••••'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
