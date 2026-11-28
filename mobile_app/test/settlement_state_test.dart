import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/widgets/job_card.dart';

import 'worker_home_test.dart' show WorkerApi, FixedLocation;

class SettlementWorkerApi extends WorkerApi {
  SettlementWorkerApi() {
    applied = true;
    applicationStatus = 'ACCEPTED';
  }
  bool paid = false;
  @override
  Job get job => Job(
    id: 1,
    contractorId: 2,
    contractorName: 'Chủ thầu',
    contractorPhone: '0900000002',
    title: 'Công trình chờ thanh toán',
    description: '',
    jobType: 'Thợ chính',
    salaryPerDay: 250000,
    address: 'QA',
    latitude: 10,
    longitude: 106,
    requiredWorkers: 1,
    status: paid ? 'COMPLETED' : 'IN_PROGRESS',
    recruitmentClosed: true,
    ratingsFinalizedAt: DateTime.utc(2030, 3, 1),
  );
  @override
  JobApplication get application => JobApplication(
    id: 1,
    job: job,
    workerId: 3,
    workerName: 'Thợ QA',
    workerPhone: null,
    workerRating: 5,
    workerVerified: false,
    workerActive: true,
    status: 'ACCEPTED',
    jobRating: 5,
    paidAt: paid ? DateTime.utc(2030, 3, 1, 10) : null,
  );
}

void main() {
  test('a finalized rating does not change an unpaid work item into completed or stopped recruitment', () {
    final api = SettlementWorkerApi();
    expect(api.job.status, 'IN_PROGRESS');
    expect(api.job.displayStatus, 'IN_PROGRESS');
    expect(api.job.canRecruit, isFalse);
    expect(api.application.awaitingPayment, isTrue);
    api.paid = true;
    expect(api.job.displayStatus, 'COMPLETED');
    expect(api.application.awaitingPayment, isFalse);
    expect(api.application.paidAt, isNotNull);
    api.dispose();
  });
  testWidgets(
    'rated but unpaid work remains on the workers active list with a payment hint',
    (tester) async {
      final api = SettlementWorkerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeContent(
            api: api,
            location: FixedLocation(),
            tab: 1,
            onTabChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hint = find.text('Đã đánh giá · Chờ thanh toán');
      await tester.scrollUntilVisible(
        hint,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(hint);
      await tester.pumpAndSettle();
      expect(hint, findsOneWidget);
      expect(
        tester.widget<JobCard>(find.byType(JobCard)).job.displayStatus,
        'IN_PROGRESS',
      );
      expect(find.text('Hủy việc đang làm'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
