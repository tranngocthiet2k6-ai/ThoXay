import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/incident.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/widgets/incident_report_dialog.dart';
import 'package:tho_xay_mobile/screens/incidents_screen.dart';

const fixture = Job(
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
);

class DeniedGps extends LocationService {
  @override
  Future<GeoPoint> currentPosition() async =>
      throw const LocationFailure('Chưa cho phép GPS');
}

class IncidentApi extends ApiService {
  bool failFirst = false, resolved = false;
  final requests = <Map<String, dynamic>>[];
  int reads = 0;
  IncidentDetail detail() => IncidentDetail.fromJson({
    'incident': {
      'id': 7,
      'jobId': 1,
      'jobTitle': 'Công trường QA',
      'type': 'SOS',
      'status': resolved ? 'RESOLVED' : 'IN_REVIEW',
      'description': 'Cần hỗ trợ QA',
      'adminNote': resolved ? 'Đã có kết quả QA' : 'Admin đã tiếp nhận QA',
      'createdAt': '2030-01-01T01:00:00Z',
    },
    'history': [
      {
        'status': resolved ? 'RESOLVED' : 'IN_REVIEW',
        'note': resolved ? 'Đã có kết quả QA' : 'Admin đã tiếp nhận QA',
        'createdAt': '2030-01-01T02:00:00Z',
      },
    ],
  });
  @override
  Future<IncidentDetail> reportIncident(
    int jobId,
    Map<String, dynamic> body,
  ) async {
    requests.add(Map.of(body));
    if (failFirst && requests.length == 1) {
      throw const ApiException('Mất kết nối QA');
    }
    return detail();
  }

  @override
  Future<IncidentDetail> incident(int id) async {
    reads++;
    return detail();
  }

  @override
  Future<IncidentPage> myIncidents({int? jobId, int? beforeId}) async =>
      IncidentPage.fromJson({'items': [], 'hasMore': false});
}

Widget dialogHost(IncidentApi api, {LocationService? location}) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showDialog<IncidentDetail>(
          context: context,
          builder: (_) => IncidentReportDialog(
            api: api,
            job: fixture,
            sos: true,
            location: location,
          ),
        ),
        child: const Text('Mở SOS'),
      ),
    ),
  ),
);
void main() {
  testWidgets('SOS needs explicit send and denied GPS never blocks reporting', (
    tester,
  ) async {
    final api = IncidentApi();
    await tester.pumpWidget(dialogHost(api, location: DeniedGps()));
    await tester.tap(find.text('Mở SOS'));
    await tester.pumpAndSettle();
    expect(api.requests, isEmpty);
    await tester.ensureVisible(find.text('Đính kèm GPS (tùy chọn)'));
    await tester.tap(find.text('Đính kèm GPS (tùy chọn)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bạn vẫn có thể gửi báo cáo'), findsOneWidget);
    await tester.ensureVisible(find.text('Xác nhận gửi SOS'));
    await tester.tap(find.text('Xác nhận gửi SOS'));
    await tester.pumpAndSettle();
    expect(api.requests.single['type'], 'SOS');
    expect(api.requests.single.containsKey('latitude'), isFalse);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('retry freezes original report and request key', (tester) async {
    final api = IncidentApi()..failFirst = true;
    await tester.pumpWidget(dialogHost(api));
    await tester.tap(find.text('Mở SOS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận gửi SOS'));
    await tester.pumpAndSettle();
    expect(find.text('Mất kết nối QA'), findsOneWidget);
    await tester.tap(find.text('Xác nhận gửi SOS'));
    await tester.pumpAndSettle();
    expect(api.requests.length, 2);
    expect(api.requests[0], api.requests[1]);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('report history refresh shows actual Admin resolution', (
    tester,
  ) async {
    final api = IncidentApi();
    await tester.pumpWidget(
      MaterialApp(home: IncidentDetailScreen(api: api, id: 7)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin đang xử lý'), findsWidgets);
    api.resolved = true;
    await tester.tap(find.byTooltip('Làm mới báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Đã có kết quả'), findsWidgets);
    expect(api.reads, 2);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
