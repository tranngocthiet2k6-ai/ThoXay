import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tho_xay_mobile/models/deposit.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/deposit_dialog.dart';

class DepositApi extends ApiService {
  bool failFirst = false, approved = false, demo = false;
  int calls = 0;
  final ids = <String>[];
  Deposit data() => Deposit.fromJson({
    'requestId': 1,
    'amount': 100000,
    'status': approved ? 'APPROVED' : 'PENDING',
    'reference': 'TXQA1',
    'bankName': 'Ngân hàng QA',
    'bankBin': demo ? '000000' : '970000',
    'accountNo': '000001234567',
    'accountName': 'QA RECEIVER',
    'payload': 'qa-fixture-only',
  });
  @override
  Future<Deposit> createDeposit(int amount, String clientRequestId) async {
    calls++;
    ids.add(clientRequestId);
    if (failFirst && calls == 1) {
      throw const ApiException('Kết nối quá thời gian');
    }
    return data();
  }

  @override
  Future<Deposit> deposit(int id) async => data();
}

void main() {
  testWidgets('demo QR clearly warns against sending real money', (
    tester,
  ) async {
    final api = DepositApi()..demo = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DepositDialog(api: api, requestId: 1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CHẾ ĐỘ DEMO · KHÔNG CHUYỂN TIỀN'), findsOneWidget);
    expect(
      find.textContaining('Kiểm tra người nhận trong ứng dụng ngân hàng'),
      findsNothing,
    );
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
    'amount validation precedes QR creation and shows receiving snapshot',
    (tester) async {
      final api = DepositApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DepositDialog(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('deposit-amount')),
        '900',
      );
      await tester.tap(find.text('Tạo QR nạp tiền'));
      await tester.pump();
      expect(api.calls, 0);
      await tester.enterText(
        find.byKey(const ValueKey('deposit-amount')),
        '100000',
      );
      await tester.tap(find.text('Tạo QR nạp tiền'));
      await tester.pumpAndSettle();
      expect(api.calls, 1);
      expect(api.ids.single.length, 32);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('000001234567'), findsOneWidget);
      expect(find.text('TXQA1'), findsOneWidget);
      expect(find.text('QA RECEIVER'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('network retry preserves idempotency key', (tester) async {
    final api = DepositApi()..failFirst = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DepositDialog(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('deposit-amount')),
      '100000',
    );
    await tester.tap(find.text('Tạo QR nạp tiền'));
    await tester.pumpAndSettle();
    expect(find.text('Kết nối quá thời gian'), findsOneWidget);
    await tester.tap(find.text('Tạo QR nạp tiền'));
    await tester.pumpAndSettle();
    expect(api.calls, 2);
    expect(api.ids[0], api.ids[1]);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
    'already approved request does not invite a second bank transfer',
    (tester) async {
      final api = DepositApi()..approved = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DepositDialog(api: api, requestId: 1)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('TXQA1'), findsOneWidget);
      expect(find.text('Tạo QR nạp tiền'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
