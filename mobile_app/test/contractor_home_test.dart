import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

class ContractorApi extends ApiService {
  String decision = 'PENDING';
  bool closed = false, failStop = false;
  int stopCalls = 0;
  Job get job => Job(
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
    status: closed && decision == 'ACCEPTED' ? 'IN_PROGRESS' : 'OPEN',
    recruitmentClosed: closed,
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

  @override
  Future<Job> stopRecruiting(int jobId) async {
    stopCalls++;
    if (failStop) throw const ApiException('Không kết nối được máy chủ');
    closed = true;
    if (decision == 'PENDING') decision = 'REJECTED';
    return job;
  }
}

void main() {
  Future<void> openManagement(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Quản lý công trình'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quản lý công trình'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dừng tuyển'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'stopping recruitment requires confirmation and updates the job',
    (tester) async {
      final api = ContractorApi();
      await tester.pumpWidget(
        MaterialApp(home: ContractorHomeScreen(api: api)),
      );
      await tester.pumpAndSettle();
      await openManagement(tester);
      await tester.tap(find.text('Dừng tuyển'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(api.stopCalls, 0);
      await tester.tap(find.text('Dừng tuyển'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận dừng tuyển'));
      await tester.pumpAndSettle();
      expect(api.stopCalls, 1);
      expect(api.decision, 'REJECTED');
      expect(find.text('Dừng tuyển'), findsNothing);
      expect(find.text('Sửa công trình'), findsNothing);
      expect(find.text('Đã dừng tuyển'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'accepted workers retain completion action after stopping recruitment',
    (tester) async {
      final api = ContractorApi()..decision = 'ACCEPTED';
      await tester.pumpWidget(
        MaterialApp(home: ContractorHomeScreen(api: api)),
      );
      await tester.pumpAndSettle();
      await openManagement(tester);
      await tester.tap(find.text('Dừng tuyển'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận dừng tuyển'));
      await tester.pumpAndSettle();
      expect(api.decision, 'ACCEPTED');
      expect(find.text('Hoàn thành công trình'), findsOneWidget);
      expect(find.text('Dừng tuyển'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets('stopping from job details closes stale actions', (tester) async {
    final api = ContractorApi();
    await tester.pumpWidget(MaterialApp(home: ContractorHomeScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Xem chi tiết'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem chi tiết'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dừng tuyển'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận dừng tuyển'));
    await tester.pumpAndSettle();
    expect(api.stopCalls, 1);
    expect(find.text('Dừng tuyển'), findsNothing);
    expect(find.text('Đã dừng tuyển'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets('failed stop keeps recruitment action available for retry', (
    tester,
  ) async {
    final api = ContractorApi()..failStop = true;
    await tester.pumpWidget(MaterialApp(home: ContractorHomeScreen(api: api)));
    await tester.pumpAndSettle();
    await openManagement(tester);
    await tester.tap(find.text('Dừng tuyển'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận dừng tuyển'));
    await tester.pumpAndSettle();
    expect(api.closed, isFalse);
    expect(find.text('Không kết nối được máy chủ'), findsOneWidget);
    expect(find.text('Dừng tuyển'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'payroll preview stays finite while invalid salary input is being edited',
    (tester) async {
      final api = ContractorApi();
      await tester.pumpWidget(
        MaterialApp(home: ContractorHomeScreen(api: api)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đăng công trình mới'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Đăng công trình mới'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lương mỗi ngày (đồng)'),
        'Infinity',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Đăng việc'));
      await tester.pumpAndSettle();
      expect(find.text('Lương từ 1 đến 1.000.000.000 đồng'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('contractor reviews worker and sees approval count', (
    tester,
  ) async {
    final api = ContractorApi();
    await tester.pumpWidget(MaterialApp(home: ContractorHomeScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Duyệt thợ'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duyệt thợ'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn Thợ'), findsOneWidget);
    await tester.ensureVisible(find.text('Duyệt nhận việc'));
    await tester.tap(find.text('Duyệt nhận việc'));
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
    await tester.ensureVisible(find.text('Đăng công trình mới'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng công trình mới'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng việc'));
    await tester.pump();
    expect(find.text('Nhập tên công trình'), findsOneWidget);
    expect(find.text('Nhập địa chỉ công trình'), findsOneWidget);
    api.dispose();
  });
}
