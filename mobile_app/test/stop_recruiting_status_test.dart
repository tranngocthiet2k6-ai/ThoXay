import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/widgets/job_card.dart';

Job closedJob(String status) => Job(
  id: 1,
  contractorId: 2,
  contractorName: 'Chủ thầu',
  contractorPhone: null,
  title: 'Công trình đã dừng',
  description: '',
  jobType: 'Thợ chính',
  salaryPerDay: 500000,
  address: 'TP.HCM',
  latitude: 10,
  longitude: 106,
  requiredWorkers: 3,
  status: status,
  recruitmentClosed: true,
);

void main() {
  test(
    'stopped recruitment is the displayed status even with accepted workers',
    () {
      expect(closedJob('IN_PROGRESS').displayStatus, 'RECRUITMENT_CLOSED');
      expect(closedJob('COMPLETED').displayStatus, 'COMPLETED');
    },
  );
  testWidgets('compact job card shows stopped status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobCard(
            job: closedJob('IN_PROGRESS'),
            previewOnly: true,
            action: const SizedBox(),
          ),
        ),
      ),
    );
    expect(find.text('Đã dừng tuyển'), findsOneWidget);
  });
}
