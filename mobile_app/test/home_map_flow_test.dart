import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/widgets/job_card.dart';
import 'package:tho_xay_mobile/widgets/figma_job_map.dart';

import 'package:tho_xay_mobile/widgets/work_commitment.dart';

import 'worker_home_test.dart'
    show WorkerApi, FixedLocation, NegotiatingWorkerApi;
import 'contractor_home_test.dart' show ContractorApi;

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final worker in [true, false]) {
    testWidgets('expanded home map retains actual job cards: worker=$worker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final workerApi = WorkerApi(), contractorApi = ContractorApi();
      await tester.pumpWidget(
        MaterialApp(
          home: worker
              ? WorkerHomeScreen(api: workerApi, location: FixedLocation())
              : ContractorHomeScreen(api: contractorApi),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(JobMapPreview), findsOneWidget);
      final expand = find.text('Xem bản đồ');
      expect(expand, findsOneWidget);
      await tester.ensureVisible(expand);
      await tester.pumpAndSettle();
      await tester.tap(expand);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(JobCard).first,
        350,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 10,
      );
      expect(find.byType(JobCard), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      workerApi.dispose();
      contractorApi.dispose();
    });
  }

  for (final worker in [true, false]) {
    testWidgets(
      'pin summary closes to list and fresh home resets expansion: worker=$worker',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'isMapExpanded': true,
          'showMap': true,
        });
        final workerApi = WorkerApi(), contractorApi = ContractorApi();
        Widget home() => MaterialApp(
          home: worker
              ? WorkerHomeScreen(api: workerApi, location: FixedLocation())
              : ContractorHomeScreen(api: contractorApi),
        );
        await tester.pumpWidget(home());
        await tester.pumpAndSettle();
        expect(
          tester.widget<JobMapPreview>(find.byType(JobMapPreview)).expanded,
          isFalse,
        );
        await tapVisible(tester, find.text('Xem bản đồ'));
        await tapVisible(tester, find.byKey(const ValueKey('job-marker-1')));
        expect(find.text('Công trình trên bản đồ'), findsOneWidget);
        expect(
          find.text(worker ? 'Nhận việc' : 'Duyệt thợ').hitTestable(),
          findsOneWidget,
        );
        if (!worker) expect(find.text('Nhận việc'), findsNothing);
        await tapVisible(tester, find.text('Đóng / Xem danh sách công trình'));
        expect(find.byType(JobCard).hitTestable(), findsWidgets);
        expect(workerApi.applied, isFalse);
        await tester.ensureVisible(find.byType(JobMapPreview));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('Xem bản đồ'));
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(home());
        await tester.pumpAndSettle();
        expect(
          tester.widget<JobMapPreview>(find.byType(JobMapPreview)).expanded,
          isFalse,
        );
        await tester.pumpWidget(const SizedBox());
        workerApi.dispose();
        contractorApi.dispose();
      },
    );
  }

  testWidgets('receive from a map pin still requires the work commitment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = NegotiatingWorkerApi();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerHomeScreen(api: api, location: FixedLocation()),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('job-marker-1')));
    await tapVisible(tester, find.text('Nhận việc'));
    expect(find.byType(WorkCommitmentDialog), findsOneWidget);
    expect(api.submitted, isNull);
    expect(api.applied, isFalse);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(api.applied, isFalse);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'already applied pin cannot submit a duplicate and details stay available',
    (tester) async {
      final api = WorkerApi()..applied = true;
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('job-marker-1')));
      final applied = find.widgetWithText(FilledButton, 'Đã ứng tuyển');
      expect(tester.widget<FilledButton>(applied).onPressed, isNull);
      await tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, 'Xem chi tiết'),
      );
      expect(find.byKey(const ValueKey('job-detail-actions')), findsOneWidget);
      expect(find.text('Công trình trên bản đồ'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
