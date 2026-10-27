import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tho_xay_mobile/services/kyc_camera.dart';
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
  Future<UserProfile> uploadCccd(KycPhoto front, KycPhoto back) async {
    cccdUpdates++;
    return person = UserProfile(
      id: 3,
      fullName: 'Thợ A',
      phoneNumber: '0900000003',
      role: 'ROLE_WORKER',
      verified: false,
      rating: 4,
      cccdFrontImage: '/admin/kyc/images/front',
      cccdBackImage: '/admin/kyc/images/back',
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

class FakeCamera extends KycCamera {
  final faces = <String>[];
  bool cancel = false, denied = false;
  @override
  bool get usesFileSelection => false;
  @override
  Future<({String face, KycPhoto photo})?> recover(int userId) async => null;
  @override
  Future<KycPhoto?> capture(int userId, String face) async {
    faces.add(face);
    if (denied) throw PlatformException(code: 'camera_access_denied');
    if (cancel) return null;
    return KycPhoto(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
      ),
    );
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
    'camera requires both faces then uploads and resets verification',
    (tester) async {
      final api = LifecycleApi();
      final camera = FakeCamera();
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(api: api, camera: camera),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa có đánh giá công trình'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Cập nhật CCCD'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cập nhật CCCD'));
      await tester.pumpAndSettle();
      expect(api.cccdUpdates, 0);
      expect(
        find.text('Hãy chụp đủ mặt trước và mặt sau CCCD trước khi gửi.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('capture-front')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('capture-front')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('capture-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('capture-back')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cập nhật CCCD'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cập nhật CCCD'));
      await tester.pumpAndSettle();
      expect(api.cccdUpdates, 1);
      expect(api.person.verified, false);
      expect(camera.faces, ['front', 'back']);
      expect(find.byType(Image), findsNothing);
      api.dispose();
    },
  );
  testWidgets(
    'camera cancellation and permission denial keep existing verified profile',
    (tester) async {
      final api = LifecycleApi();
      final camera = FakeCamera()..cancel = true;
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(api: api, camera: camera),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('capture-front')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('capture-front')));
      await tester.pumpAndSettle();
      expect(api.cccdUpdates, 0);
      expect(api.person.verified, true);
      camera.cancel = false;
      camera.denied = true;
      await tester.tap(find.byKey(const ValueKey('capture-front')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không mở được camera.'), findsOneWidget);
      expect(api.cccdUpdates, 0);
      expect(api.person.verified, true);
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
