import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/scheduling.dart';
import 'package:tho_xay_mobile/models/wallet.dart';
import 'package:tho_xay_mobile/screens/job_payments_screen.dart';
import 'package:tho_xay_mobile/screens/calendar_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/work_commitment.dart';

final scheduledJob = Job(
  id: 7,
  contractorId: 2,
  contractorName: 'Chủ thầu QA',
  contractorPhone: null,
  title: 'Công trình có lịch',
  description: '',
  jobType: 'Thợ chính',
  salaryPerDay: 300000,
  address: 'QA',
  latitude: 10,
  longitude: 106,
  requiredWorkers: 2,
  status: 'OPEN',
  startsOn: DateTime(2030),
  endsOn: DateTime(2030, 1, 3),
  termsVersion: 3,
);

class SchedulingApi extends ApiService {
  int? requestedRate;
  bool choseOffer = false, removed = false;
  CommitmentDocument document(int rate) => CommitmentDocument.fromJson({
    'termsVersion': 3,
    'state': 'DRAFT',
    'text': 'Lương $rate đ/ngày. Hủy việc trừ 15 điểm.',
    'selectedDailyRate': rate,
  });
  @override
  Future<CommitmentDocument> jobTerms(int id, {int? proposedRate}) async {
    requestedRate = proposedRate;
    return document(proposedRate ?? 300000);
  }

  @override
  Future<CommitmentDocument> commitment(
    int id, {
    bool acceptOffer = false,
  }) async {
    choseOffer = acceptOffer;
    return document(acceptOffer ? 450000 : 300000);
  }

  @override
  Future<List<CalendarEntry>> calendar(DateTime from, DateTime to) async => [
    CalendarEntry.fromJson({
      'kind': 'JOB',
      'referenceId': 7,
      'title': 'Công trình đã nhận',
      'startsOn': isoDay(from),
      'endsOn': isoDay(from),
    }),
    if (!removed)
      CalendarEntry.fromJson({
        'kind': 'BLOCKED',
        'referenceId': 8,
        'title': 'Ngày bận cá nhân',
        'startsOn': isoDay(from),
        'endsOn': isoDay(from),
      }),
  ];
  @override
  Future<void> removeCalendarBlock(int id) async {
    removed = true;
  }
}

class NegotiatedPaymentApi extends ApiService {
  @override
  Future<WalletBalance> wallet() async => WalletBalance.fromJson({
    'mainBalance': 2000000,
    'escrowBalance': 0,
    'heldBalance': 0,
    'minimumEscrow': 200000,
    'lowEscrow': true,
  });
  @override
  Future<List<JobPayment>> jobPayments(int id) async => [];
  @override
  Future<List<JobApplication>> jobApplications(int id) async => [
    JobApplication(
      id: 1,
      job: scheduledJob,
      workerId: 3,
      workerName: 'Thợ QA',
      workerPhone: null,
      workerRating: 5,
      workerVerified: false,
      workerActive: true,
      status: 'ACCEPTED',
      jobRating: 5,
      agreedDailyRate: 450000,
    ),
  ];
}

void main() {
  testWidgets(
    'payment confirmation uses negotiated rate rather than advertised salary',
    (tester) async {
      final api = NegotiatedPaymentApi();
      await tester.pumpWidget(
        MaterialApp(
          home: JobPaymentsScreen(api: api, job: scheduledJob),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Thanh toán cho Thợ QA'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Thanh toán cho Thợ QA'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Đơn giá: 450.000 đ/ngày'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '2');
      await tester.pumpAndSettle();
      expect(find.text('Tổng thanh toán: 900.000 đ'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'worker reviews updated offer and explicitly consents before submitting',
    (tester) async {
      final api = SchedulingApi();
      WorkProposal? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await showWorkProposal(context, api, scheduledJob),
                child: const Text('Mở cam kết'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở cam kết'));
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(FilledButton, 'Đồng ý & ứng tuyển');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('proposal-rate')),
        '450000',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Cập nhật cam kết'));
      await tester.tap(find.text('Cập nhật cam kết'));
      await tester.pumpAndSettle();
      expect(api.requestedRate, 450000);
      await tester.ensureVisible(
        find.byKey(const ValueKey('commitment-consent')),
      );
      await tester.tap(find.byKey(const ValueKey('commitment-consent')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(result?.rate, 450000);
      expect(result?.version, 3);
      api.dispose();
    },
  );
  testWidgets('contractor chooses counter offer and confirms selected terms', (
    tester,
  ) async {
    final api = SchedulingApi();
    HiringDecision? result;
    final application = JobApplication(
      id: 1,
      job: scheduledJob,
      workerId: 3,
      workerName: 'Thợ QA',
      workerPhone: null,
      workerRating: 5,
      workerVerified: false,
      workerActive: true,
      status: 'PENDING',
      proposedDailyRate: 450000,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showHiringCommitment(
                context,
                api,
                application,
              ),
              child: const Text('Duyệt'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Duyệt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chấp nhận mức đề xuất'));
    await tester.pumpAndSettle();
    expect(api.choseOffer, isTrue);
    await tester.ensureVisible(
      find.byKey(const ValueKey('commitment-consent')),
    );
    await tester.tap(find.byKey(const ValueKey('commitment-consent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận nhận thợ'));
    await tester.pumpAndSettle();
    expect(result?.acceptOffer, isTrue);
    expect(result?.version, 3);
    api.dispose();
  });
  testWidgets(
    'calendar shows bookings and removes only personal blocked days',
    (tester) async {
      final api = SchedulingApi();
      await tester.pumpWidget(MaterialApp(home: CalendarScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Ngày bận cá nhân'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Xóa ngày bận'));
      await tester.pumpAndSettle();
      expect(api.removed, isTrue);
      expect(find.text('Ngày bận cá nhân'), findsNothing);
      expect(find.text('Công trình đã nhận'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
