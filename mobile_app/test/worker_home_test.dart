import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/location_service.dart';

class FixedLocation extends LocationService {
  @override
  Future<GeoPoint> currentPosition() async => const GeoPoint(10.7769, 106.7009);
}

class WorkerApi extends ApiService {
  bool applied = false;
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
      distanceKm: 0);
  JobApplication get application => JobApplication(
      id: 1,
      job: job,
      workerId: 3,
      workerName: 'Thợ',
      workerPhone: '0900000003',
      workerRating: 5,
      workerVerified: false,
      workerActive: true,
      status: 'PENDING');
  @override
  Future<List<Job>> nearby(double lat, double lng, double radius) async =>
      [job];
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
    await tester.pumpWidget(MaterialApp(
        home: WorkerHomeScreen(api: api, location: FixedLocation())));
    await tester.pumpAndSettle();
    expect(find.text('Xây nhà phố'), findsOneWidget);
    await tester.ensureVisible(find.text('Nhận việc'));
    await tester.tap(find.text('Nhận việc'));
    await tester.pumpAndSettle();
    expect(api.applied, isTrue);
    await tester.tap(find.text('Đã ứng tuyển').last);
    await tester.pumpAndSettle();
    expect(find.text('Chờ duyệt'), findsOneWidget);
    api.dispose();
  });
}
