import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/models/attendance.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/contractor_team.dart';
import 'package:tho_xay_mobile/screens/attendance_radar_screen.dart';
import 'package:tho_xay_mobile/screens/attendance_screen.dart';
import 'package:tho_xay_mobile/screens/job_payments_screen.dart';
import 'package:tho_xay_mobile/screens/main_shell.dart';
import 'package:tho_xay_mobile/screens/contractor_team_screen.dart';
import 'package:tho_xay_mobile/screens/wallet_screen.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/private_image.dart';
import 'package:tho_xay_mobile/widgets/shift_code_dialog.dart';

import 'attendance_test.dart' show AttendanceApi, Gps, fixture;
import 'role_tier_ui_test.dart' show RoleTierApi;
import 'wallet_test.dart' show WalletApi;
import 'contractor_team_test.dart' show TeamApi;

const _longName = 'Nguyễn Văn Thợ Chuyên Thi Công Hoàn Thiện Công Trình';
const _job = Job(
  id: 1,
  contractorId: 2,
  contractorName: 'Chủ thầu xây dựng và hoàn thiện nhà dân dụng',
  contractorPhone: null,
  title: 'Công trình nhà phố nhiều tầng và hoàn thiện nội ngoại thất',
  description: 'Xây tô và nghiệm thu công việc cuối ngày.',
  jobType: 'Thợ chính',
  salaryPerDay: 450000,
  address: 'Phường Phú Bài, thành phố Huế',
  latitude: 10,
  longitude: 106,
  requiredWorkers: 3,
  status: 'IN_PROGRESS',
);

class _ShellApi extends RoleTierApi {
  @override
  Future<List<ContractorGroup>> contractorGroups() async => [];
  @override
  Future<List<TeamContact>> teamContacts() async => [];
  @override
  Future<bool> availability() async => true;
  @override
  Future<List<Job>> nearby(
    double lat,
    double lng,
    double radius, {
    String? jobType,
    String sort = 'DISTANCE',
  }) async => [_job];
  @override
  Future<List<Job>> contractorJobs() async => [_job];
  @override
  Future<List<JobApplication>> workerApplications() async => [
    JobApplication(
      id: 3,
      job: _job,
      workerId: 3,
      workerName: _longName,
      workerPhone: null,
      workerRating: 5,
      workerVerified: true,
      workerActive: true,
      status: 'ACCEPTED',
    ),
  ];
  @override
  Future<UserProfile> profile() async => UserProfile(
    id: 3,
    fullName: _longName,
    phoneNumber: '0900000003',
    role: activeRole,
    verified: true,
    rating: 4.8,
    cccdFrontImage: 'https://example.com/front.png',
    cccdBackImage: 'https://example.com/back.png',
  );
}

class _PhotosApi extends AttendanceApi {
  @override
  AttendancePage data() => AttendancePage.fromJson({
    'today': '2030-03-01',
    'hasMore': false,
    'items': [
      {
        'id': 1,
        'applicationId': 3,
        'workerName': _longName,
        'workDay': '2030-03-01',
        'checkedInAt': '2030-03-01T01:00:00Z',
        'checkedOutAt': '2030-03-01T10:00:00Z',
        'checkinMethod': 'GPS',
        'checkoutMethod': 'QR',
        'logId': 5,
        'logVersion': 2,
        'hasDetailPhoto': true,
        'caption': 'Toàn cảnh và chi tiết kết quả công việc cuối ngày',
        'reviewStatus': reviewed ? 'APPROVED' : 'PENDING',
      },
    ],
  });
}

class _ShiftApi extends AttendanceApi {
  @override
  Future<ShiftCode> shiftCode(int jobId) async => ShiftCode.fromJson({
    'jobId': jobId,
    'token': 'a' * 43,
    'expiresAt': DateTime.now()
        .add(const Duration(minutes: 5))
        .toIso8601String(),
  });
}

class _FailingPayrollApi extends WalletApi {
  bool unavailable = true;
  @override
  Future<List<JobApplication>> jobApplications(int id) async {
    if (unavailable) {
      throw const ApiException('Không tải được danh sách thanh toán');
    }
    return super.jobApplications(id);
  }
}

class _FailingTeamApi extends TeamApi {
  bool unavailable = true;
  @override
  Future<List<ContractorGroup>> contractorGroups() async {
    if (unavailable) throw const ApiException('Không tải được nhóm thợ');
    return super.contractorGroups();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void size(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  test('radar never presents invalid GPS accuracy as valid attendance', () {
    const site = GeoPoint(10, 106);
    for (final accuracy in [0.0, -1.0, double.negativeInfinity, double.nan]) {
      expect(
        validAttendancePosition(
          GeoPoint(10, 106, accuracyMeters: accuracy),
          site,
        ),
        isFalse,
        reason: 'Backend rejects accuracy=$accuracy; radar must agree.',
      );
    }
    expect(
      validAttendancePosition(const GeoPoint(10, 106, accuracyMeters: 8), site),
      isTrue,
    );
  });

  for (final viewport in [const Size(360, 800), const Size(390, 844)]) {
    testWidgets('team API failure displays retry and recovers at $viewport', (
      tester,
    ) async {
      size(tester, viewport);
      final api = _FailingTeamApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_CONTRACTOR'),
          home: Scaffold(body: ContractorTeamScreen(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Không tải được nhóm thợ'), findsOneWidget);
      api.unavailable = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được nhóm thợ'), findsNothing);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });

    for (final worker in [true, false]) {
      testWidgets(
        'five main tabs preserve wallet state at $viewport worker=$worker',
        (tester) async {
          size(tester, viewport);
          final api = _ShellApi()
            ..activeRole = worker ? 'ROLE_WORKER' : 'ROLE_CONTRACTOR';
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.forRole(api.activeRole),
              home: MainShell(api: api, worker: worker, location: Gps()),
            ),
          );
          await tester.pumpAndSettle();
          final destinations = (tester.widget<NavigationBar>(
            find.byType(NavigationBar),
          )).destinations.cast<NavigationDestination>();
          expect(destinations.length, 5);
          expect(destinations.elementAt(2).label, 'Quét QR');
          Future<void> tab(int index) async {
            await tester.tap(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(destinations.elementAt(index).label),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              tester
                  .widget<NavigationBar>(find.byType(NavigationBar))
                  .selectedIndex,
              index,
            );
            expect(find.byType(BackButton), findsNothing);
          }

          await tab(1);
          await tab(2);
          await tab(3);
          final walletState = tester.state(find.byType(WalletScreen));
          await tester.tap(find.byTooltip('Ẩn số dư'));
          await tester.pumpAndSettle();
          await tab(4);
          await tab(3);
          expect(
            identical(tester.state(find.byType(WalletScreen)), walletState),
            isTrue,
          );
          expect(find.byTooltip('Hiện số dư'), findsOneWidget);
          await tab(0);
          await tester.pumpWidget(const SizedBox());
          api.dispose();
        },
      );

      testWidgets(
        'both end-of-shift photos remain viewable at $viewport worker=$worker',
        (tester) async {
          size(tester, viewport);
          final api = _PhotosApi();
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.forRole(
                worker ? 'ROLE_WORKER' : 'ROLE_CONTRACTOR',
              ),
              home: AttendanceScreen(
                api: api,
                job: _job,
                applicationId: worker ? 3 : null,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Đã gửi 2/2 ảnh · Toàn cảnh và chi tiết'),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(find.byType(PrivateImage), findsNWidgets(2));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          api.dispose();
        },
      );
    }

    testWidgets('five-minute shift QR fits $viewport', (tester) async {
      size(tester, viewport);
      final api = _ShiftApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_CONTRACTOR'),
          home: Scaffold(body: ShiftCodeDialog(api: api, jobId: 1)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Còn 4 phút'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });

    testWidgets('payroll can recover from a failed load at $viewport', (
      tester,
    ) async {
      size(tester, viewport);
      final api = _FailingPayrollApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_CONTRACTOR'),
          home: JobPaymentsScreen(api: api, job: fixture),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không tải được danh sách thanh toán'), findsOneWidget);
      api.unavailable = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được danh sách thanh toán'), findsNothing);
      expect(find.textContaining('Thanh toán cho'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }
}
