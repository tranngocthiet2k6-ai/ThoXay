import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/empty_state.dart';
import 'package:tho_xay_mobile/widgets/job_card.dart';
import 'package:tho_xay_mobile/widgets/loading_jobs.dart';

import 'worker_home_test.dart' show FixedLocation;

class DelayedJobsApi extends ApiService {
  final result = Completer<List<Job>>();
  @override
  Future<List<JobApplication>> workerApplications() async => [];
  @override
  Future<List<Job>> nearby(
    double lat,
    double lng,
    double radius, {
    String? jobType,
    String sort = 'DISTANCE',
  }) => result.future;
}

void main() {
  testWidgets(
    'shimmer ends on empty response and shows friendly recovery action',
    (tester) async {
      final api = DelayedJobsApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(LoadingJobs), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      api.result.complete([]);
      await tester.pumpAndSettle();
      expect(find.byType(LoadingJobs), findsNothing);
      await tester.ensureVisible(find.byType(EmptyState));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy công trình quanh đây'), findsOneWidget);
      expect(find.text('Đổi vị trí tìm kiếm'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'failed request does not pretend the search returned no results',
    (tester) async {
      final api = DelayedJobsApi();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pump();
      api.result.completeError(
        const ApiException('Không kết nối được máy chủ'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không kết nối được máy chủ'), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(LoadingJobs), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'skeleton stops animating for reduced motion and inactive routes',
    (tester) async {
      for (final reduce in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: TickerMode(
                enabled: reduce,
                child: const Scaffold(
                  body: SingleChildScrollView(child: LoadingJobs()),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.binding.hasScheduledFrame, isFalse);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'job card and illustration fit narrow screens with large Vietnamese text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const job = Job(
        id: 1,
        contractorId: 2,
        contractorName: 'Chủ thầu Nguyễn Văn An',
        contractorPhone: null,
        title: 'Cần phụ hồ xây dựng công trình nhà phố nhiều tầng',
        description: '',
        jobType: 'Phụ hồ',
        salaryPerDay: 1200000,
        address: 'Đường Nguyễn Thị Minh Khai, Phường Bến Thành, Thành phố Hồ Chí Minh',
        latitude: 10,
        longitude: 106,
        requiredWorkers: 12,
        status: 'IN_PROGRESS',
        distanceKm: 99.9,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    JobCard(
                      job: job,
                      action: FilledButton(
                        onPressed: () {},
                        child: const Text('Nhận việc'),
                      ),
                    ),
                    const EmptyState(
                      title: 'Không tìm thấy công trình quanh đây',
                      message: 'Thử đổi vị trí để khám phá thêm công trình.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
