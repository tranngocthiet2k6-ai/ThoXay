import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tho_xay_mobile/models/attendance.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/qr_action.dart';
import 'package:tho_xay_mobile/models/worker_profile.dart';
import 'package:tho_xay_mobile/screens/qr_hub_screen.dart';
import 'package:tho_xay_mobile/screens/attendance_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/widgets/vietqr_review.dart';

import 'attendance_test.dart' show AttendanceApi, fixture;
import 'contractor_team_test.dart' show worker;

const bankQr =
    '00020101021238560010A0000007270126000697043601120000012345670208QRIBFTTA530370454061000005802VN62130809TXQA1234563041385';
const personalBankQr =
    '00020101021138540010A00000072701240006970407011096020919960208QRIBFTTA53037045802VN630434A0';
final shiftQr = jsonEncode({
  'type': 'THOXAY_ATTENDANCE',
  'jobId': 1,
  'token': 'A' * 43,
});

class QrApi extends AttendanceApi {
  QrApi({this.contractor = false});
  final bool contractor;
  bool accepted = true, expired = false;
  int marks = 0, codes = 0;
  int? saved;
  @override
  AuthSession get session => AuthSession(
    token: 'test-only',
    userId: contractor ? 2 : 3,
    fullName: 'QA',
    phoneNumber: '0900000003',
    role: contractor ? 'ROLE_CONTRACTOR' : 'ROLE_WORKER',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  @override
  Future<List<Job>> contractorJobs() async => [fixture];
  @override
  Future<List<JobApplication>> workerApplications() async => [
    JobApplication(
      id: 3,
      job: fixture,
      workerId: 3,
      workerName: 'Thợ QA',
      workerRating: 5,
      workerVerified: true,
      workerActive: true,
      workerPhone: null,
      status: accepted ? 'ACCEPTED' : 'PENDING',
    ),
  ];
  @override
  Future<WorkerProfile> workerProfile(int id) async => worker;
  @override
  Future<void> saveWorker(int id, bool value) async {
    saved = id;
  }

  @override
  Future<ShiftCode> shiftCode(int id) async {
    codes++;
    return ShiftCode.fromJson({
      'jobId': id,
      'token': 'A' * 43,
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 5))
          .toIso8601String(),
    });
  }

  @override
  Future<AttendancePage> markAttendance(
    int id,
    bool checkout, {
    GeoPoint? position,
    String? qrToken,
  }) async {
    if (expired) {
      throw const ApiException(
        'Mã ca làm sai hoặc đã hết hạn; xin mã mới từ chủ thầu',
      );
    }
    marks++;
    return super.markAttendance(
      id,
      checkout,
      position: position,
      qrToken: qrToken,
    );
  }
}

Future<void> mountHub(
  WidgetTester tester,
  QrApi api, {
  required String payload,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QrHubScreen(
          api: api,
          worker: !api.contractor,
          active: true,
          scannerBuilder: (detect) => FilledButton(
            onPressed: () {
              detect(payload);
              detect(payload);
            },
            child: const Text('Phát hiện mã'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> scan(WidgetTester tester) async {
  await tester.tap(find.text('Mở camera quét QR'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Phát hiện mã'));
  await tester.pumpAndSettle();
}

void main() {
  test('QR routing validates kind, IDs, trusted links and VietQR CRC', () {
    expect(QrAction.parse(shiftQr)?.kind, QrKind.attendance);
    expect(QrAction.parse(QrAction.workerCode(3))?.id, 3);
    expect(
      QrAction.parse('https://thoxay.vercel.app/?job=3')?.kind,
      QrKind.job,
    );
    for (final value in [
      'https://evil.example/?job=3',
      'javascript:alert(1)',
      '{"type":"THOXAY_WORKER","workerId":-1}',
      '{"type":"THOXAY_ATTENDANCE","jobId":1,"token":123}',
      '000201',
      'x' * 5000,
    ]) {
      expect(QrAction.parse(value), isNull);
    }
    final payment = QrAction.parse(bankQr)!.payment!;
    expect(payment.bankBin, '970436');
    expect(payment.accountNo, '000001234567');
    expect(payment.amount, 100000);
    expect(payment.reference, 'TXQA12345');
    expect(VietQrPayment.parse(personalBankQr)!.amount, isNull);
    expect(QrAction.parse(bankQr.replaceFirst('100000', '900000')), isNull);
    final link = payment.bankLink('icb', 'vcb', 100000);
    expect(link.host, 'dl.vietqr.io');
    expect(link.queryParameters['ba'], '000001234567@vcb');
  });

  testWidgets(
    'QR attendance waits for consent, deduplicates detections and supports check-in/out',
    (tester) async {
      final api = QrApi();
      await mountHub(tester, api, payload: shiftQr);
      await scan(tester);
      expect(api.marks, 0);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(api.marks, 0);
      await scan(tester);
      await tester.tap(find.text('Vào ca'));
      await tester.pumpAndSettle();
      expect(api.marks, 1);
      expect(api.qr, 'A' * 43);
      expect(find.byType(AttendanceScreen), findsOneWidget);
      Navigator.pop(tester.element(find.byType(AttendanceScreen)));
      await tester.pumpAndSettle();
      await scan(tester);
      expect(find.text('Xác nhận kết thúc ca'), findsOneWidget);
      await tester.tap(find.text('Kết thúc ca'));
      await tester.pumpAndSettle();
      expect(api.marks, 2);
      expect(api.checkedOut, isTrue);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  for (final expired in [true, false]) {
    testWidgets(
      'QR rejects expired token or a pending application: expired=$expired',
      (tester) async {
        final api = QrApi()
          ..expired = expired
          ..accepted = expired;
        await mountHub(tester, api, payload: shiftQr);
        await scan(tester);
        if (expired) {
          await tester.tap(find.text('Vào ca'));
          await tester.pumpAndSettle();
        }
        expect(api.marks, 0);
        expect(
          find.textContaining(expired ? 'hết hạn' : 'cần được duyệt'),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }

  testWidgets(
    'contractor QR saves the server profile only after confirmation',
    (tester) async {
      final api = QrApi(contractor: true);
      await mountHub(tester, api, payload: QrAction.workerCode(3));
      await scan(tester);
      expect(api.saved, isNull);
      expect(find.textContaining('Nguyễn Văn An'), findsOneWidget);
      await tester.tap(find.text('Lưu vào Đội thợ'));
      await tester.pumpAndSettle();
      expect(api.saved, 3);
      await tester.tap(find.text('QR công trình'));
      await tester.pumpAndSettle();
      expect(api.codes, 0);
      await tester.tap(find.text('Hiển thị QR điểm danh'));
      await tester.pumpAndSettle();
      expect(api.codes, 1);
      expect(find.byType(QrImageView), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets('worker identity QR contains an ID and no token or phone', (
    tester,
  ) async {
    final api = QrApi();
    await mountHub(tester, api, payload: '');
    await tester.tap(find.text('Mã QR của tôi'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(jsonDecode(QrAction.workerCode(api.session.userId)), {
      'type': 'THOXAY_WORKER',
      'workerId': 3,
    });
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets('camera is detached when leaving QR mode or its main tab', (
    tester,
  ) async {
    final api = QrApi();
    Widget home(bool active) => MaterialApp(
      home: Scaffold(
        body: QrHubScreen(
          api: api,
          worker: true,
          active: active,
          scannerBuilder: (_) =>
              const SizedBox(key: ValueKey('camera-test'), height: 200),
        ),
      ),
    );
    await tester.pumpWidget(home(true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở camera quét QR'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('camera-test')), findsOneWidget);
    await tester.pumpWidget(home(false));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('camera-test')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'VietQR review opens banking after confirmation without crediting wallet',
    (tester) async {
      Uri? launched;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VietQrReview(
              payment: VietQrPayment.parse(bankQr)!,
              bankResolver: (_) async => 'vcb',
              launcher: (uri) async {
                launched = uri;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(launched, isNull);
      await tester.ensureVisible(find.text('Mở ứng dụng ngân hàng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mở ứng dụng ngân hàng'));
      await tester.pumpAndSettle();
      expect(launched?.queryParameters['ba'], '000001234567@vcb');
      expect(find.textContaining('chưa xác nhận thanh toán'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
