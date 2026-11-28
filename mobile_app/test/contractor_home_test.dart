import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/models/scheduling.dart';
import 'package:tho_xay_mobile/widgets/figma_job_map.dart';

class ContractorApi extends ApiService {
  String decision = 'PENDING';
  bool closed = false, failStop = false, completed = false;
  int stopCalls = 0;
  Map<String, dynamic>? createdBody;
  Map<String, dynamic>? updatedBody;

  @override
  Future<Job> createJob(Map<String, dynamic> body) async {
    createdBody = body;
    return job;
  }

  @override
  Future<Job> updateJob(int id, Map<String, dynamic> body) async {
    updatedBody = body;
    return job;
  }

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
    status: completed
        ? 'IN_PROGRESS'
        : closed && decision == 'ACCEPTED'
        ? 'IN_PROGRESS'
        : 'OPEN',
    recruitmentClosed: closed || completed,
    ratingsFinalizedAt: completed ? DateTime.utc(2030, 3, 1) : null,
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

  @override
  Future<Job> completeJob(int jobId, Map<int, int> ratings) async {
    completed = true;
    return job;
  }
}

class StaffedContractorApi extends ContractorApi {
  @override
  Job get job => Job(
    id: 1,
    contractorId: 2,
    contractorName: 'Chủ thầu',
    contractorPhone: null,
    title: 'Xây tường',
    description: 'Cam kết cũ',
    jobType: 'Thợ chính, Phụ hồ',
    salaryPerDay: 250000,
    address: 'Quận 1',
    latitude: 10,
    longitude: 106,
    requiredWorkers: 5,
    skilledWorkers: 2,
    helpers: 3,
    status: 'IN_PROGRESS',
    startsOn: DateUtils.dateOnly(DateTime.now())
        .subtract(const Duration(days: 1)),
    endsOn: DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 2)),
  );
  @override
  Future<List<JobApplication>> jobApplications(int jobId) async => [
    application,
    JobApplication(
      id: 2,
      job: job,
      workerId: 4,
      workerName: 'Thợ thứ hai',
      workerPhone: null,
      workerRating: 5,
      workerVerified: false,
      workerActive: true,
      status: 'ACCEPTED',
    ),
  ];
}

void main() {
  testWidgets('posting form uses the available phone width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.reset);
    final api = ContractorApi();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forRole('ROLE_CONTRACTOR'),
        home: ContractorHomeScreen(api: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đăng công trình mới'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng công trình mới'));
    await tester.pumpAndSettle();
    final skilledRect = tester.getRect(
      find.byKey(const ValueKey('quantity-Thợ chính')),
    );
    final helpersRect = tester.getRect(
      find.byKey(const ValueKey('quantity-Phụ hồ')),
    );
    expect(skilledRect.top, helpersRect.top);
    expect(skilledRect.right, lessThan(helpersRect.left));
    expect(
      tester
          .getSize(find.widgetWithText(TextFormField, 'Tên công trình'))
          .width,
      greaterThanOrEqualTo(312),
    );
    expect(
      find.widgetWithText(FilledButton, 'Đăng việc').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('posting uses the chosen dates and updates the payroll preview', (
    tester,
  ) async {
    final api = ContractorApi();
    await tester.pumpWidget(MaterialApp(home: ContractorHomeScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đăng công trình mới'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng công trình mới'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tăng số Thợ chính'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Giảm số Thợ chính'));
    await tester.tap(find.text('Phụ hồ').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('quantity-Thợ chính')),
      '2',
    );
    await tester.enterText(find.byKey(const ValueKey('quantity-Phụ hồ')), '4');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Giảm số Phụ hồ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('300.000 VND'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('300.000 VND'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Lương mỗi ngày'),
          )
          .controller!
          .text,
      '300000',
    );
    for (final field in {
      'Tên công trình': 'Xây nhà',
      'Lương mỗi ngày': '500000',
      'Địa chỉ công trình': 'Quận 1',
    }.entries) {
      await tester.enterText(
        find.widgetWithText(TextFormField, field.key),
        field.value,
      );
    }
    await tester.ensureVisible(find.byType(JobLocationPin));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(JobLocationPin)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bắt đầu ngày mai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu ngày mai'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Làm 7 ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Làm 7 ngày'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dự toán quỹ lương'));
    await tester.pumpAndSettle();
    expect(find.text('17.500.000 VND'), findsOneWidget);
    expect(find.textContaining('5 thợ × 7 ngày.'), findsOneWidget);
    await tester.tap(find.text('Đăng việc'));
    await tester.pumpAndSettle();
    expect(api.createdBody?['salaryPerDay'], 500000);
    expect(api.createdBody?['jobType'], 'Thợ chính, Phụ hồ');
    expect(api.createdBody?['skilledWorkers'], 2);
    expect(api.createdBody?['helpers'], 3);
    expect(api.createdBody?['requiredWorkers'], 5);
    final today = DateUtils.dateOnly(DateTime.now());
    expect(
      api.createdBody?['startsOn'],
      isoDay(DateTime(today.year, today.month, today.day + 1)),
    );
    expect(
      api.createdBody?['endsOn'],
      isoDay(DateTime(today.year, today.month, today.day + 7)),
    );
    expect(find.text('Đã đăng công trình mới.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

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

  testWidgets('editing keeps the existing salary and can save a quick amount', (
    tester,
  ) async {
    final api = ContractorApi();
    await tester.pumpWidget(MaterialApp(home: ContractorHomeScreen(api: api)));
    await tester.pumpAndSettle();
    await openManagement(tester);
    await tester.ensureVisible(find.text('Sửa công trình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa công trình'));
    await tester.pumpAndSettle();
    final salary = find.widgetWithText(TextFormField, 'Lương mỗi ngày');
    expect(tester.widget<TextFormField>(salary).controller!.text, '500000');
    await tester.ensureVisible(find.text('250.000 VND'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('250.000 VND'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(api.updatedBody?['salaryPerDay'], 250000);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'staffed job edits only quantities and preserves old dates and pay',
    (tester) async {
      final api = StaffedContractorApi()..decision = 'ACCEPTED';
      await tester.pumpWidget(
        MaterialApp(home: ContractorHomeScreen(api: api)),
      );
      await tester.pumpAndSettle();
      await openManagement(tester);
      await tester.ensureVisible(find.text('Sửa công trình'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sửa công trình'));
      await tester.pumpAndSettle();
      expect(find.text('Điều chỉnh số lượng thợ'), findsOneWidget);
      expect(find.textContaining('Đã nhận 2 thợ.'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Lương mỗi ngày'),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('quantity-Thợ chính')),
        '1',
      );
      final dialog = find.byType(Dialog);
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Phụ hồ')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(api.updatedBody, isNull);
      expect(
        find.textContaining('Tổng số cần tuyển phải ít nhất 2 người.'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Phụ hồ')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('quantity-Phụ hồ')),
        '1',
      );
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(api.updatedBody?['requiredWorkers'], 2);
      expect(api.updatedBody?['salaryPerDay'], 250000);
      expect(api.updatedBody?['description'], 'Cam kết cũ');
      expect(api.updatedBody?['startsOn'], isoDay(api.job.startsOn!));
      expect(api.updatedBody?['endsOn'], isoDay(api.job.endsOn!));
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

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
      expect(find.text('Chốt đánh giá'), findsOneWidget);
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

  testWidgets('completing from details closes the stale job sheet', (
    tester,
  ) async {
    final api = ContractorApi()
      ..closed = true
      ..decision = 'ACCEPTED';
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
    await tester.tap(find.text('Chốt đánh giá'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chấm 5 sao cho Nguyễn Văn Thợ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chốt đánh giá & mở thanh toán'));
    await tester.pumpAndSettle();
    expect(api.completed, isTrue);
    expect(find.text('Thông tin công việc'), findsNothing);
    expect(find.text('Chốt đánh giá'), findsNothing);
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
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
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
        find.widgetWithText(TextFormField, 'Lương mỗi ngày'),
        'Infinity',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Đăng việc'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Lương phải trên 200.000 và không quá 1.000.000.000 VND/ngày',
        ),
        findsOneWidget,
      );
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
