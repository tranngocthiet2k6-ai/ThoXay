import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/attendance.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/attendance_screen.dart';

import 'attendance_test.dart' show AttendanceApi, fixture;

class TargetedAttendanceApi extends AttendanceApi {
  bool completed = false;
  int? reviewedLog;
  Map<int, int>? submitted;
  Job get currentJob => Job(
    id: 1,
    contractorId: 2,
    contractorName: 'QA',
    contractorPhone: null,
    title: fixture.title,
    description: '',
    jobType: 'Thợ chính',
    salaryPerDay: 350000,
    address: 'QA',
    latitude: 10,
    longitude: 106,
    requiredWorkers: 2,
    status: 'IN_PROGRESS',
    ratingsFinalizedAt: completed ? DateTime.utc(2030, 3, 1) : null,
    recruitmentClosed: completed,
  );
  @override
  Future<List<JobApplication>> jobApplications(int id) async => [
    for (final worker in [(3, 'Thợ An'), (4, 'Thợ Bình')])
      JobApplication(
        id: worker.$1,
        job: currentJob,
        workerId: worker.$1,
        workerName: worker.$2,
        workerPhone: null,
        workerRating: 5,
        workerVerified: false,
        workerActive: true,
        status: 'ACCEPTED',
        jobRating: completed ? (worker.$1 == 3 ? 3 : 5) : null,
      ),
  ];
  @override
  AttendancePage data() => AttendancePage.fromJson({
    'today': '2030-03-01',
    'hasMore': false,
    'items': [
      for (final worker in [(3, 'Thợ An'), (4, 'Thợ Bình')])
        {
          'id': worker.$1,
          'applicationId': worker.$1,
          'workerId': worker.$1,
          'workerName': worker.$2,
          'workDay': '2030-03-01',
          'checkedInAt': '2030-03-01T01:00:00Z',
          'checkedOutAt': '2030-03-01T09:00:00Z',
          'logId': worker.$1 + 10,
          'logVersion': 2,
          'caption': 'Ảnh của ${worker.$2}',
          'reviewStatus': 'PENDING',
        },
    ],
  });
  @override
  Future<void> reviewWorkLog(
    int id,
    int version,
    bool approved,
    String feedback,
  ) async {
    reviewedLog = id;
  }

  @override
  Future<Job> completeJob(int jobId, Map<int, int> ratings) async {
    submitted = Map.of(ratings);
    completed = true;
    return currentJob;
  }
}

void main() {
  testWidgets('photo review requires pressing the named workers own action', (
    tester,
  ) async {
    final api = TargetedAttendanceApi();
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(api: api, job: fixture),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Nghiệm thu & Mở khóa thanh toán'),
      findsNothing,
      reason:
          'No worker may be selected automatically for a shared review action',
    );
    final action = find.byKey(const ValueKey('review-log-14'));
    await tester.scrollUntilVisible(
      action,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.textContaining('Thợ Bình'), findsWidgets);
    expect(
      find.textContaining('Người nhận phản hồi: Thợ Bình'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byType(TextFormField),
      'Ảnh của anh Bình đạt yêu cầu',
    );
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(api.reviewedLog, 14);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
    'reopening attendance reads completed ratings and cannot rate again',
    (tester) async {
      final api = TargetedAttendanceApi()..completed = true;
      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceScreen(api: api, job: fixture),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đánh giá & hoàn thành'), findsNothing);
      expect(find.text('Đã chốt đánh giá · 3/5 sao'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Đã chốt đánh giá · 5/5 sao'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Đã chốt đánh giá · 5/5 sao'), findsOneWidget);
      expect(api.submitted, isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'each named rating is submitted once and remains locked after reopening',
    (tester) async {
      final api = TargetedAttendanceApi();
      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceScreen(api: api, job: fixture),
        ),
      );
      await tester.pumpAndSettle();
      for (final worker in [('Thợ An', 3), ('Thợ Bình', 5)]) {
        final star = find.byTooltip('Chấm ${worker.$2} sao cho ${worker.$1}');
        await tester.scrollUntilVisible(
          star,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(star);
        await tester.pumpAndSettle();
        await tester.tap(star);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Chốt đánh giá'));
      await tester.pumpAndSettle();
      expect(api.submitted, isNull);
      await tester.tap(find.text('Chốt đánh giá & mở thanh toán'));
      await tester.pumpAndSettle();
      expect(api.submitted, {3: 3, 4: 5});
      expect(find.text('Chốt đánh giá'), findsNothing);
      expect(find.text('Mở thanh toán ngày công'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceScreen(api: api, job: fixture),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chốt đánh giá'), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Chấm 3 sao cho Thợ An',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'phone exposes accidental checkout report without searching below photos',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final api = AttendanceApi()
        ..checkedIn = true
        ..checkedOut = true;
      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceScreen(api: api, job: fixture, applicationId: 3),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Báo kết thúc nhầm').hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
