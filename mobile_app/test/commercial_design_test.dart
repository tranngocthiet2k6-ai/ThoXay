import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/commercial_hero.dart';
import 'package:tho_xay_mobile/screens/attendance_radar_screen.dart';
import 'package:tho_xay_mobile/screens/commitment_screen.dart';
import 'package:tho_xay_mobile/models/scheduling.dart';
import 'package:tho_xay_mobile/services/location_service.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

void main() {
  test('incident evidence carries the same retry ID and JWT in one multipart request', () async {
    SharedPreferences.setMockInitialValues({});
    var uploads = 0;
    final api = ApiService(
      baseUrl: 'http://localhost:8080',
      client: MockClient((r) async {
        if (r.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'token': 'qa',
              'userId': 3,
              'fullName': 'QA',
              'phoneNumber': '0900000003',
              'role': 'ROLE_WORKER',
              'expiresIn': 3600,
            }),
            200,
          );
        }
        uploads++;
        expect(r.url.path, '/api/jobs/7/incidents/with-photo');
        expect(r.headers['Authorization'], 'Bearer qa');
        expect(latin1.decode(r.bodyBytes), contains('evidence-request-01'));
        expect(latin1.decode(r.bodyBytes), contains('name="photo"'));
        return http.Response(
          jsonEncode({
            'incident': {
              'id': 1,
              'jobId': 7,
              'jobTitle': 'QA',
              'type': 'SAFETY',
              'status': 'NEW',
              'description': 'QA',
              'createdAt': '2030-01-01T00:00:00Z',
            },
            'history': [],
            'evidencePath': '/api/incidents/1/evidence',
          }),
          200,
        );
      }),
    );
    await api.login('0900000003', 'password');
    final result = await api.reportIncidentWithPhoto(7, {
      'type': 'SAFETY',
      'description': 'QA',
      'clientRequestId': 'evidence-request-01',
    }, Uint8List.fromList([1, 2, 3]));
    expect(result.evidencePath, '/api/incidents/1/evidence');
    expect(uploads, 1);
    api.dispose();
  });
  test('two-party confirmation requires both recorded timestamps', () {
    final doc = CommitmentDocument.fromJson({
      'applicationId': 42,
      'termsVersion': 1,
      'text': 'server',
      'state': 'FINAL',
      'hash': null,
      'selectedDailyRate': 450000,
      'workerConfirmedAt': '2030-01-01T00:00:00Z',
      'contractorConfirmedAt': '2030-01-01T01:00:00Z',
      'workerVerified': true,
      'contractorVerified': false,
    });
    expect(doc.bothConfirmed, isTrue);
    expect(doc.workerVerified, isTrue);
    expect(doc.contractorVerified, isFalse);
  });
  test('radar derives distance and rejects poor or absent GPS accuracy', () {
    const site = GeoPoint(10.8015, 106.714);
    const near = GeoPoint(10.801815, 106.714, accuracyMeters: 8);
    expect(attendanceDistance(near, site), closeTo(35, 1));
    expect(validAttendancePosition(near, site), isTrue);
    expect(
      validAttendancePosition(
        const GeoPoint(10.81, 106.714, accuracyMeters: 8),
        site,
      ),
      isFalse,
    );
    expect(
      validAttendancePosition(
        const GeoPoint(10.8015, 106.714, accuracyMeters: 101),
        site,
      ),
      isFalse,
    );
    expect(validAttendancePosition(site, site), isFalse);
  });
  testWidgets(
    'a FINAL snapshot alone never claims two confirmations or verified parties',
    (tester) async {
      final doc = CommitmentDocument.fromJson({
        'applicationId': 42,
        'termsVersion': 1,
        'text': 'Điều khoản server',
        'state': 'FINAL',
        'hash': null,
        'selectedDailyRate': 450000,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommitmentSummary(document: doc),
            ),
          ),
        ),
      );
      expect(find.text('Đã xác nhận bởi 2 bên'), findsNothing);
      expect(find.text('Đã KYC'), findsNothing);
      expect(find.text('CK-000042'), findsOneWidget);
      expect(find.textContaining('chưa giữ hoặc bảo lãnh'), findsOneWidget);
    },
  );
  testWidgets(
    'commercial hero keeps financial text legible and availability truthful',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_WORKER'),
          home: const Scaffold(
            body: CommercialHero(
              child: Column(
                children: [
                  Text('2.450.000đ'),
                  PresenceAvatar(name: 'Nguyễn An', online: false),
                ],
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('2.450.000đ'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, Colors.white);
      expect(find.bySemanticsLabel('Tạm ngưng nhận việc'), findsOneWidget);
      expect(find.bySemanticsLabel('Sẵn sàng nhận việc'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
