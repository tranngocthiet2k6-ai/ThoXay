import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

class ContractorApi extends ApiService {
  String decision = 'PENDING';
  final job = const Job(
    id: 1,
    contractorId: 2,
    contractorName: 'Chủ thầu',
    contractorPhone: '0900000002',
    title: 'Công trình A',
    description: '',
    jobType: 'Thợ chính',
    salaryPerDay: 500000,
    address: 'Quận 1',
    latitude: 10,
    longitude: 106,
    requiredWorkers: 1,
    status: 'OPEN',
  );
  JobApplication get application => JobApplication(
    id: 1,
    job: job,
    workerId: 3,
    workerName: 'Nguyễn Văn Thợ',
    workerPhone: '0900000003',
    workerRating: 5,
    workerVerified: true,
    workerActive: true,
    status: decision,
  );
  @override
  Future<List<Job>> contractorJobs() async => [job];
  @override
  Future<List<JobApplication>> jobApplications(int jobId) async => [
    application,
  ];
  @override
  Future<JobApplication> updateApplication(int id, String status) async {
    decision = status;
    return application;
  }
}

void main() {
  testWidgets('contractor reviews worker and sees approval count', (
    tester,
  ) async {
    final api = ContractorApi();
    await tester.pumpWidget(MaterialApp(home: ContractorHomeScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Xem & duyệt thợ'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem & duyệt thợ'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn Thợ'), findsOneWidget);
    await tester.ensureVisible(find.text('Nhận thợ'));
    await tester.tap(find.text('Nhận thợ'));
    await tester.pumpAndSettle();
    expect(api.decision, 'ACCEPTED');
    expect(find.text('Đã nhận 1 / 1 thợ'), findsOneWidget);
    expect(find.text('Gọi thợ: 0900000003'), findsOneWidget);
    expect(find.text('Nhắn tin'), findsOneWidget);
    api.dispose();
  });
  testWidgets('post job form validates required fields', (tester) async {
    final api = ContractorApi();
    await tester.pumpWidget(MaterialApp(home: ContractorHomeScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng công trình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng việc'));
    await tester.pump();
    expect(find.text('Nhập tên công trình'), findsOneWidget);
    expect(find.text('Nhập địa chỉ công trình'), findsOneWidget);
    api.dispose();
  });
}
