import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/widgets/call_button.dart';
import 'package:tho_xay_mobile/models/scheduling.dart';
import 'package:tho_xay_mobile/widgets/job_application_actions.dart';

class FixedLocation extends LocationService {
  @override
  Future<GeoPoint> currentPosition() async => const GeoPoint(10.7769, 106.7009);
}

class NegotiatingWorkerApi extends WorkerApi {
  WorkProposal? submitted;
  int? termsRate;
  @override
  Job get job => Job(
    id: 1,
    contractorId: 2,
    contractorName: 'Chủ thầu',
    contractorPhone: null,
    title: 'Công trình có lịch',
    description: '',
    jobType: 'Thợ chính',
    salaryPerDay: 500000,
    address: 'Quận 1',
    latitude: 10,
    longitude: 106,
    requiredWorkers: 1,
    status: 'OPEN',
    startsOn: DateTime(2030),
    endsOn: DateTime(2030, 1, 2),
    termsVersion: 3,
  );
  @override
  Future<CommitmentDocument> jobTerms(int id, {int? proposedRate}) async {
    termsRate = proposedRate;
    return CommitmentDocument.fromJson({
      'termsVersion': 3,
      'state': 'DRAFT',
      'text': 'Cam kết đúng mức lương đã chọn',
      'selectedDailyRate': proposedRate ?? 500000,
    });
  }

  @override
  Future<JobApplication> applyWithTerms(int id, WorkProposal proposal) async {
    submitted = proposal;
    applied = true;
    return application;
  }
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
      await tester.scrollUntilVisible(
        find.byType(TextField),
        160,
        scrollable: find.byType(Scrollable).first,
      );
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
      expect(find.text('Ứng tuyển ngay'), findsNothing);
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
      await tester.tap(find.text('Việc của tôi').last);
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
      await Scrollable.ensureVisible(tester.element(find.text('Xây nhà phố')), alignment: .4);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xây nhà phố'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ứng tuyển ngay'));
      await tester.pumpAndSettle();
      expect(api.applied, isTrue);
      await tester.tap(find.text('Việc của tôi').last);
      await tester.pumpAndSettle();
      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('Nhắn tin'), findsNothing);
      expect(find.byType(CallButton), findsNothing);
      api.dispose();
    },
  );
  testWidgets(
    'negotiation opens only on demand and preserves offer and consent',
    (tester) async {
      final api = NegotiatingWorkerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Công trình có lịch'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
    await Scrollable.ensureVisible(tester.element(find.text('Công trình có lịch')), alignment: .4);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công trình có lịch'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('offer-rate')), findsNothing);
      final bar = tester.widget<JobApplicationActions>(
        find.byType(JobApplicationActions),
      );
      expect(bar.onChat, isNull);
      await tester.tap(find.text('Thương lượng giá'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('offer-rate')),
        '450000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('offer-note')),
        'Có kinh nghiệm ốp lát',
      );
      await tester.tap(find.text('Xem cam kết'));
      await tester.pumpAndSettle();
      expect(api.termsRate, 450000);
      expect(api.submitted, isNull);
      final submit = find.widgetWithText(FilledButton, 'Đồng ý & ứng tuyển');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('commitment-consent')),
      );
      await tester.tap(find.byKey(const ValueKey('commitment-consent')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.submitted?.rate, 450000);
      expect(api.submitted?.note, 'Có kinh nghiệm ốp lát');
      expect(api.submitted?.version, 3);
      await tester.pumpWidget(const SizedBox());
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
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Phụ hồ'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
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
    await tester.tap(find.text('Việc của tôi').last);
    await tester.pumpAndSettle();
    expect(find.text('Gọi chủ thầu: 0900000002'), findsOneWidget);
    expect(find.text('Nhắn tin'), findsOneWidget);
    expect(find.text('Hủy việc đang làm'), findsNothing);
    api.dispose();
  });
}
