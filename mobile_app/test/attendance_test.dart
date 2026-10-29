import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tho_xay_mobile/models/attendance.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/attendance_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/location_service.dart';

class Gps extends LocationService {
  @override
  Future<GeoPoint> currentPosition() async =>
      const GeoPoint(10, 106, accuracyMeters: 8);
}

final fixture = Job(
  id: 1,
  contractorId: 2,
  contractorName: 'QA',
  contractorPhone: null,
  title: 'Công trường QA',
  description: '',
  jobType: 'Thợ chính',
  salaryPerDay: 350000,
  address: 'QA',
  latitude: 10,
  longitude: 106,
  requiredWorkers: 1,
  status: 'IN_PROGRESS',
  startsOn: DateTime(2030, 3, 1),
  endsOn: DateTime(2030, 3, 2),
  attendanceRequired: true,
);

class AttendanceApi extends ApiService {
  bool checkedIn = false,
      checkedOut = false,
      reviewed = false,
      withPhoto = false;
  int reviews = 0;
  String? qr;
  double? accuracy;
  AttendancePage data() => AttendancePage.fromJson({
    'today': '2030-03-01',
    'hasMore': false,
    'items': [
      if (checkedIn)
        {
          'id': 1,
          'applicationId': 3,
          'workerName': 'Thợ QA',
          'workDay': '2030-03-01',
          'checkedInAt': '2030-03-01T01:00:00Z',
          'checkedOutAt': checkedOut ? '2030-03-01T10:00:00Z' : null,
          'logId': withPhoto ? 5 : null,
          'logVersion': withPhoto ? 2 : null,
          'caption': 'Tô tường cuối ngày',
          'reviewStatus': withPhoto
              ? (reviewed ? 'APPROVED' : 'PENDING')
              : null,
          'feedback': '',
        },
    ],
  });
  @override
  Future<AttendancePage> attendance(int id, {DateTime? beforeDay}) async =>
      data();
  @override
  Future<AttendancePage> jobAttendance(
    int id,
    DateTime day, {
    int page = 0,
  }) async => data();
  @override
  Future<AttendancePage> markAttendance(
    int id,
    bool checkout, {
    GeoPoint? position,
    String? qrToken,
  }) async {
    qr = qrToken;
    accuracy = position?.accuracyMeters;
    checkedIn = true;
    checkedOut = checkout;
    return data();
  }

  @override
  Future<Uint8List> privateImage(String path) async =>
      TileProvider.transparentImage;
  @override
  Future<void> reviewWorkLog(
    int id,
    int version,
    bool approved,
    String feedback,
  ) async {
    expect(id, 5);
    expect(version, 2);
    expect(approved, isTrue);
    reviews++;
    reviewed = true;
  }
}

void main() {
  test('QR parser rejects other job IDs and unrelated QR payloads', () {
    final code = ShiftCode.fromJson({
      'jobId': 1,
      'token': 'a' * 43,
      'expiresAt': '2030-03-01T01:05:00Z',
    });
    expect(ShiftCode.parse(code.qr, 1), 'a' * 43);
    expect(ShiftCode.parse(code.qr, 2), isNull);
    expect(ShiftCode.parse('https://example.com', 1), isNull);
    expect(ShiftCode.parse('{"type":"other","jobId":1}', 1), isNull);
  });
  testWidgets('worker check-in and check-out use measured GPS accuracy', (
    tester,
  ) async {
    final api = AttendanceApi();
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(
          api: api,
          job: fixture,
          applicationId: 3,
          location: Gps(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check-in GPS'));
    await tester.pumpAndSettle();
    expect(api.checkedIn, isTrue);
    expect(api.accuracy, 8);
    expect(find.text('Check-out GPS'), findsOneWidget);
    await tester.tap(find.text('Check-out GPS'));
    await tester.pumpAndSettle();
    expect(api.checkedOut, isTrue);
    expect(find.text('Gửi ảnh cuối ngày'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('manual shift token is sent only after explicit confirmation', (
    tester,
  ) async {
    final api = AttendanceApi();
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(api: api, job: fixture, applicationId: 3),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhập mã ca làm'));
    await tester.pumpAndSettle();
    expect(api.checkedIn, isFalse);
    await tester.enterText(find.byType(TextFormField), 'b' * 43);
    await tester.tap(find.text('Xác nhận chấm công'));
    await tester.pumpAndSettle();
    expect(api.qr, 'b' * 43);
    expect(api.accuracy, isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('contractor confirms photo review with the viewed version', (
    tester,
  ) async {
    final api = AttendanceApi()
      ..checkedIn = true
      ..checkedOut = true
      ..withPhoto = true;
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(api: api, job: fixture),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Nghiệm thu ngày công'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nghiệm thu ngày công'));
    await tester.tap(find.text('Nghiệm thu ngày công'));
    await tester.pumpAndSettle();
    expect(api.reviews, 0);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(api.reviews, 1);
    expect(find.text('Đã nghiệm thu'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
