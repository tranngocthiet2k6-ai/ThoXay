import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/widgets/call_button.dart';

class FixedLocation extends LocationService {
  @override
  Future<GeoPoint> currentPosition() async => const GeoPoint(10.7769, 106.7009);
}

class WorkerApi extends ApiService {
  bool online = true;
  @override
  Future<bool> availability() async => online;
  @override
  Future<bool> setAvailability(bool value) async => online = value;
  bool applied = false;
  String applicationStatus = 'PENDING';
  String jobStatus = 'OPEN';
  String? cancelReason;
  int cancelCalls = 0;
  String? lastJobType;
  String lastSort = 'DISTANCE';
  Job get job => Job(
    id: 1,
    contractorId: 2,
    contractorName: 'Chủ thầu',
    contractorPhone: '0900000002',
    title: 'Xây nhà phố',
    description: 'Bao cơm',
    jobType: 'Thợ chính',
    salaryPerDay: 500000,
    address: 'Quận 1',
    latitude: 10.7769,
    longitude: 106.7009,
    requiredWorkers: 1,
    status: jobStatus,
    distanceKm: 0,
  );
  JobApplication get application => JobApplication(
    id: 1,
    job: job,
    workerId: 3,
    workerName: 'Thợ',
    workerPhone: '0900000003',
    workerRating: 5,
    workerVerified: false,
    workerActive: true,
    status: applicationStatus,
    cancellationReason: cancelReason,
    cancellationPenalty: applicationStatus == 'CANCELLED' ? 15 : 0,
  );
  @override
  Future<List<Job>> nearby(
    double lat,
    double lng,
    double radius, {
    String? jobType,
    String sort = 'DISTANCE',
  }) async {
    lastJobType = jobType;
    lastSort = sort;
    return [job];
  }

  @override
  Future<List<JobApplication>> workerApplications() async =>
      applied ? [application] : [];
  @override
  Future<JobApplication> apply(int jobId) async {
    applied = true;
    return application;
  }

  @override
  Future<JobApplication> cancelApplication(int id, String reason) async {
    cancelCalls++;
    cancelReason = reason;
    applicationStatus = 'CANCELLED';
    return application;
  }
}

void main() {
  testWidgets(
    'sticky search filters local results without changing server filters',
    (tester) async {
      final api = WorkerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'không khớp');
      await tester.pumpAndSettle();
      expect(find.text('Xây nhà phố'), findsNothing);
      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Xây nhà phố'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Xây nhà phố'), findsOneWidget);
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.text('Xem chi tiết'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem chi tiết'));
      await tester.pumpAndSettle();
      expect(
        find
            .descendant(
              of: find.byKey(const ValueKey('job-detail-actions')),
              matching: find.byType(FilledButton),
            )
            .hitTestable(),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('job-detail-actions')),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.applied, isTrue);
      expect(find.byKey(const ValueKey('job-detail-actions')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'offline skips GPS and job discovery until the server confirms online',
    (tester) async {
      final api = WorkerApi()..online = false;
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bạn đang tạm ngưng nhận việc'), findsOneWidget);
      expect(find.text('Xây nhà phố'), findsNothing);
      expect(api.lastJobType, isNull);
      await tester.tap(find.byKey(const ValueKey('availability-switch')));
      await tester.pumpAndSettle();
      expect(api.online, isTrue);
      await tester.scrollUntilVisible(
        find.text('Xây nhà phố'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Xây nhà phố'), findsOneWidget);
      api.dispose();
    },
  );
  testWidgets(
    'cancelling work requires explicit reason and confirmation then removes contact actions',
    (tester) async {
      final api = WorkerApi()
        ..applied = true
        ..applicationStatus = 'ACCEPTED'
        ..jobStatus = 'IN_PROGRESS';
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã ứng tuyển').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Hủy việc đang làm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy việc đang làm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('trừ 15 điểm uy tín'), findsOneWidget);
      await tester.tap(find.text('Xác nhận hủy việc'));
      await tester.pumpAndSettle();
      expect(api.cancelCalls, 0);
      expect(find.text('Vui lòng nhập lý do hủy việc'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục làm việc'));
      await tester.pumpAndSettle();
      expect(api.cancelCalls, 0);
      await tester.tap(find.text('Hủy việc đang làm'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('cancellation-reason')),
        'Gia đình có việc',
      );
      await tester.tap(find.text('Xác nhận hủy việc'));
      await tester.pumpAndSettle();
      expect(api.cancelCalls, 1);
      expect(api.cancelReason, 'Gia đình có việc');
      expect(find.text('Đã hủy'), findsOneWidget);
      expect(find.text('Nhắn tin'), findsNothing);
      expect(find.byType(CallButton), findsNothing);
      expect(find.text('Hủy việc đang làm'), findsNothing);
      api.dispose();
    },
  );
  testWidgets(
    'worker finds GPS jobs, applies once and sees application history',
    (tester) async {
      final api = WorkerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Xây nhà phố'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Xây nhà phố'), findsOneWidget);
      await tester.ensureVisible(find.text('Nhận việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhận việc'));
      await tester.pumpAndSettle();
      expect(api.applied, isTrue);
      await tester.tap(find.text('Đã ứng tuyển').last);
      await tester.pumpAndSettle();
      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('Nhắn tin'), findsNothing);
      expect(find.byType(CallButton), findsNothing);
      api.dispose();
    },
  );
  testWidgets('worker filters type and requests highest salary order', (
    tester,
  ) async {
    final api = WorkerApi();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerHomeScreen(api: api, location: FixedLocation()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Phụ hồ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Phụ hồ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilterChip, 'Lương cao nhất'),
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Lương cao nhất'));
    await tester.pumpAndSettle();
    expect(api.lastJobType, 'Phụ hồ');
    expect(api.lastSort, 'SALARY_DESC');
    api.dispose();
  });
  testWidgets('accepted worker sees contractor phone and call action', (
    tester,
  ) async {
    final api = WorkerApi()
      ..applied = true
      ..applicationStatus = 'ACCEPTED';
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerHomeScreen(api: api, location: FixedLocation()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã ứng tuyển').last);
    await tester.pumpAndSettle();
    expect(find.text('Gọi chủ thầu: 0900000002'), findsOneWidget);
    expect(find.text('Nhắn tin'), findsOneWidget);
    expect(find.text('Hủy việc đang làm'), findsNothing);
    api.dispose();
  });
}
