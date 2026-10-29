import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/wallet.dart';
import 'package:tho_xay_mobile/screens/wallet_screen.dart';
import 'package:tho_xay_mobile/screens/earnings_screen.dart';
import 'package:tho_xay_mobile/screens/job_payments_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

import 'worker_home_test.dart' show WorkerApi;

class WalletApi extends ApiService {
  int main = 500000;
  bool failFirst = true;
  final submitted = <Map<String, dynamic>>[];
  String period = '';
  int? cursor;
  Map<String, dynamic>? paid;
  @override
  Future<WalletBalance> wallet() async => WalletBalance.fromJson({
    'mainBalance': main,
    'escrowBalance': 0,
    'heldBalance': 0,
    'minimumEscrow': 200000,
    'lowEscrow': true,
  });
  @override
  Future<WalletPage<WalletEntry>> walletEntries({int? beforeId}) async {
    cursor = beforeId;
    return WalletPage([
      WalletEntry.fromJson({
        'id': beforeId == null ? 2 : 1,
        'kind': 'TOP_UP',
        'amount': 10000,
        'description': beforeId == null ? 'Nạp mới' : 'Nạp cũ',
        'createdAt': '2026-10-27T00:00:00Z',
      }),
    ], beforeId == null);
  }

  @override
  Future<WalletPage<WalletRequest>> walletRequests({int? beforeId}) async =>
      WalletPage([
        WalletRequest.fromJson({
          'id': 1,
          'kind': 'TOP_UP',
          'status': 'PENDING',
          'amount': 5000,
          'createdAt': '2026-10-27T00:00:00Z',
        }),
      ], false);
  @override
  Future<void> createWalletRequest(Map<String, dynamic> input) async {
    submitted.add(Map.of(input));
    if (failFirst) {
      failFirst = false;
      throw const ApiException('Mất kết nối, hãy thử lại');
    }
  }

  @override
  Future<Earnings> earnings(String value, DateTime date) async {
    period = value;
    return Earnings.fromJson({
      'base': value == 'DAY' ? 0 : 300000,
      'tip': value == 'DAY' ? 0 : 20000,
      'bonus': value == 'DAY' ? 0 : 30000,
      'total': value == 'DAY' ? 0 : 350000,
      'settledJobs': value == 'DAY' ? 0 : 1,
      'from': '2026-10-01',
      'toExclusive': '2026-11-01',
    });
  }

  @override
  Future<List<JobApplication>> jobApplications(int id) async => [
    (WorkerApi()..applicationStatus = 'ACCEPTED').application,
  ];
  @override
  Future<List<JobPayment>> jobPayments(int id) async =>
      paid == null ? [] : [payment()];
  JobPayment payment() => JobPayment.fromJson({
    'applicationId': 1,
    'workerId': 3,
    'workDays': paid!['workDays'],
    'total': 1070000,
    'tip': paid!['tip'],
    'bonus': paid!['bonus'],
  });
  @override
  Future<JobPayment> payWorker(Map<String, dynamic> input) async {
    paid = Map.of(input);
    return payment();
  }
}

void main() {
  testWidgets(
    'balance privacy hides all three balances and never changes wallet state',
    (tester) async {
      final api = WalletApi();
      await tester.pumpWidget(MaterialApp(home: WalletScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ẩn số dư'));
      await tester.pumpAndSettle();
      expect(find.text('500.000 đ'), findsNothing);
      expect(find.text('••••••'), findsNWidgets(3));
      expect(api.main, 500000);
      await tester.tap(find.byTooltip('Hiện số dư'));
      await tester.pumpAndSettle();
      expect(find.text('500.000 đ'), findsOneWidget);
      expect(api.submitted, isEmpty);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('wallet shows real balance, low escrow and paginated history', (
    tester,
  ) async {
    final api = WalletApi();
    await tester.pumpWidget(MaterialApp(home: WalletScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('500.000 đ'), findsOneWidget);
    expect(find.textContaining('Ký quỹ thấp hơn'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Tải giao dịch cũ'), 180);
    await tester.tap(find.text('Tải giao dịch cũ'));
    await tester.pumpAndSettle();
    expect(api.cursor, 2);
    expect(find.textContaining('Nạp cũ'), findsOneWidget);
    api.dispose();
  });
  testWidgets(
    'topup validates evidence and retries with the same idempotency key',
    (tester) async {
      final api = WalletApi();
      await tester.pumpWidget(MaterialApp(home: WalletScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nạp tiền').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nạp tiền').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();
      expect(api.submitted, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('wallet-amount')),
        '5000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mã / nội dung chuyển khoản'),
        'BANK-TEST',
      );
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();
      expect(find.text('Mất kết nối, hãy thử lại'), findsOneWidget);
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();
      expect(api.submitted.length, 2);
      expect(
        api.submitted[0]['clientRequestId'],
        api.submitted[1]['clientRequestId'],
      );
      expect(api.submitted[1]['amount'], 5000);
      await tester.scrollUntilVisible(find.text('500.000 đ'), -180);
      expect(find.text('500.000 đ'), findsOneWidget);
      api.dispose();
    },
  );
  testWidgets(
    'earnings switches period and separates base tip bonus without counting topups',
    (tester) async {
      final api = WalletApi();
      await tester.pumpWidget(MaterialApp(home: EarningsScreen(api: api)));
      await tester.pumpAndSettle();
      expect(api.period, 'MONTH');
      expect(find.text('350.000 đ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('20.000 đ'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('20.000 đ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Tuần'),
        -180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Tuần'));
      await tester.pumpAndSettle();
      expect(api.period, 'WEEK');
      await tester.tap(find.text('Ngày'));
      await tester.pumpAndSettle();
      expect(api.period, 'DAY');
      await tester.scrollUntilVisible(
        find.textContaining('Chưa có thu nhập trong kỳ này'),
        180,
      );
      expect(
        find.textContaining('Chưa có thu nhập trong kỳ này'),
        findsOneWidget,
      );
      api.dispose();
    },
  );
  testWidgets(
    'contractor must enter actual workdays and confirm settlement before paying',
    (tester) async {
      final api = WalletApi()..main = 2000000;
      final job = (WorkerApi()..jobStatus = 'COMPLETED').job;
      await tester.pumpWidget(
        MaterialApp(
          home: JobPaymentsScreen(api: api, job: job),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thanh toán cho Thợ'));
      await tester.tap(find.text('Thanh toán cho Thợ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận thanh toán'));
      await tester.pumpAndSettle();
      expect(api.paid, isNull);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số ngày công đã xác nhận'),
        '2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tiền tip (VND)'),
        '50000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tiền thưởng (VND)'),
        '20000',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận thanh toán'));
      await tester.pumpAndSettle();
      expect(api.paid?['workDays'], 2);
      expect(api.paid?['tip'], 50000);
      expect(find.text('Đã thanh toán'), findsOneWidget);
      api.dispose();
    },
  );
}
