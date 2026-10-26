import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/profile_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/call_button.dart';
import 'package:tho_xay_mobile/widgets/job_completion_dialog.dart';

class LifecycleApi extends ApiService {
  Map<int, int>? submitted;
  int cccdUpdates = 0;
  UserProfile person = const UserProfile(
    id: 3,
    fullName: 'Thợ A',
    phoneNumber: '0900000003',
    role: 'ROLE_WORKER',
    verified: true,
    rating: 4,
    cccdFrontImage: 'https://example.com/old-front.jpg',
    cccdBackImage: 'https://example.com/old-back.jpg',
  );
  final job = const Job(
    id: 1,
    contractorId: 2,
    contractorName: 'Thầu A',
    contractorPhone: '0900000002',
    title: 'Công trình hoàn thành',
    description: '',
    jobType: 'Thợ chính',
    salaryPerDay: 500000,
    address: 'Quận 1',
    latitude: 10,
    longitude: 106,
    requiredWorkers: 1,
    status: 'IN_PROGRESS',
  );
  @override
  Future<UserProfile> profile() async => person;
  @override
  Future<UserProfile> updateCccd(
    String frontImageUrl,
    String backImageUrl,
  ) async {
    cccdUpdates++;
    return person = UserProfile(
      id: 3,
      fullName: 'Thợ A',
      phoneNumber: '0900000003',
      role: 'ROLE_WORKER',
      verified: false,
      rating: 4,
      cccdFrontImage: frontImageUrl,
      cccdBackImage: backImageUrl,
    );
  }

  @override
  Future<List<JobApplication>> jobApplications(int id) async => [
    JobApplication(
      id: 1,
      job: job,
      workerId: 3,
      workerName: 'Thợ A',
      workerPhone: '0900000003',
      workerRating: 4,
      workerVerified: true,
      workerActive: true,
      status: 'ACCEPTED',
    ),
  ];
  @override
  Future<Job> completeJob(int id, Map<int, int> ratings) async {
    submitted = Map.of(ratings);
    return job;
  }
}

void main() {
  testWidgets('call button opens a tel URI through the supplied launcher', (
    tester,
  ) async {
    Uri? received;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallButton(
            phone: '0900000003',
            label: 'Gọi thợ',
            launcher: (uri) async {
              received = uri;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Gọi thợ: 0900000003'));
    await tester.pumpAndSettle();
    expect(received.toString(), 'tel:0900000003');
  });
  testWidgets(
    'profile rejects insecure CCCD and shows pending verification after update',
    (tester) async {
      final api = LifecycleApi();
      await tester.pumpWidget(MaterialApp(home: ProfileScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('cccd-front-input')),
        'http://example.com/id.jpg',
      );
      await tester.scrollUntilVisible(
        find.text('Cập nhật CCCD'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cập nhật CCCD'));
      await tester.pumpAndSettle();
      expect(api.cccdUpdates, 0);
      expect(
        find.text('Nhập liên kết HTTPS hợp lệ cho mặt trước'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('cccd-front-input')),
        'https://example.com/id.jpg',
      );
      await tester.tap(find.text('Cập nhật CCCD'));
      await tester.pumpAndSettle();
      expect(api.cccdUpdates, 1);
      expect(api.person.cccdFrontImage, 'https://example.com/id.jpg');
      expect(api.person.cccdBackImage, 'https://example.com/old-back.jpg');
      expect(find.text('Chưa xác thực CCCD'), findsOneWidget);
      api.dispose();
    },
  );
  testWidgets(
    'profile requires the back face and preserves a migrated front image',
    (tester) async {
      final api = LifecycleApi()
        ..person = const UserProfile(
          id: 3,
          fullName: 'Thợ A',
          phoneNumber: '0900000003',
          role: 'ROLE_WORKER',
          verified: false,
          rating: 4,
          cccdFrontImage: 'https://example.com/front.jpg',
        );
      await tester.pumpWidget(MaterialApp(home: ProfileScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Liên kết ảnh mặt trước CCCD (HTTPS)'), findsOneWidget);
      expect(find.text('Liên kết ảnh mặt sau CCCD (HTTPS)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Cập nhật CCCD'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cập nhật CCCD'));
      await tester.pumpAndSettle();
      expect(api.cccdUpdates, 0);
      expect(
        find.text('Nhập liên kết HTTPS hợp lệ cho mặt sau'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('cccd-back-input')),
        'https://example.com/back.jpg',
      );
      await tester.tap(find.text('Cập nhật CCCD'));
      await tester.pumpAndSettle();
      expect(api.cccdUpdates, 1);
      expect(api.person.cccdFrontImage, 'https://example.com/front.jpg');
      expect(api.person.cccdBackImage, 'https://example.com/back.jpg');
      api.dispose();
    },
  );
  testWidgets(
    'completion requires explicit stars and submits the selected worker score',
    (tester) async {
      final api = LifecycleApi();
      bool? completed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  completed = await showJobCompletionDialog(
                    context,
                    api,
                    api.job,
                  );
                },
                child: const Text('Mở hoàn thành'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở hoàn thành'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Hoàn thành & lưu điểm'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Chấm 3 sao cho Thợ A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoàn thành & lưu điểm'));
      await tester.pumpAndSettle();
      expect(api.submitted, {3: 3});
      expect(completed, isTrue);
      api.dispose();
    },
  );
}
