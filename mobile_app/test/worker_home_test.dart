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
  bool applied = false;
  String applicationStatus = 'PENDING';
  String? lastJobType;
  String lastSort = 'DISTANCE';
  final job = const Job(
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
    status: 'OPEN',
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
}

void main() {
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
      expect(find.text('Xây nhà phố'), findsOneWidget);
      await tester.ensureVisible(find.text('Nhận việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhận việc'));
      await tester.pumpAndSettle();
      expect(api.applied, isTrue);
      await tester.tap(find.text('Đã ứng tuyển').last);
      await tester.pumpAndSettle();
      expect(find.text('Chờ duyệt'), findsOneWidget);
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
    await tester.tap(find.text('Tất cả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phụ hồ').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gần nhất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lương cao nhất').last);
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
    api.dispose();
  });
}
