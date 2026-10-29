import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/screens/saved_screen.dart';
import 'package:tho_xay_mobile/screens/shared_job_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/job_links.dart';
import 'package:tho_xay_mobile/widgets/job_utilities.dart';

const fixture = Job(
  id: 41,
  contractorId: 2,
  contractorName: 'Chủ thầu QA',
  contractorPhone: null,
  title: 'Nhà phố QA',
  description: 'Mô tả QA',
  jobType: 'Thợ chính',
  salaryPerDay: 500000,
  address: 'Quận 1',
  latitude: 10.7769,
  longitude: 106.7009,
  requiredWorkers: 2,
  status: 'OPEN',
);

class DiscoveryApi extends ApiService {
  bool saved = false;
  Map<String, dynamic>? updated;
  @override
  AuthSession? get session => AuthSession(
    token: 'qa',
    userId: 3,
    fullName: 'QA',
    phoneNumber: '0999999999',
    role: 'ROLE_WORKER',
    expiresAt: DateTime(2040),
  );
  @override
  Future<List<Job>> savedJobs() async => saved ? [fixture] : [];
  @override
  Future<void> saveJob(int id, bool value) async {
    saved = value;
  }

  @override
  Future<Job> fetchJob(int id) async => fixture;
  @override
  Future<List<JobApplication>> workerApplications() async => [];
  @override
  Future<List<Job>> contractorJobs() async => [fixture];
  @override
  Future<Job> updateJob(int id, Map<String, dynamic> body) async {
    updated = body;
    return fixture;
  }
}

void main() {
  test(
    'job share URL and directions contain coordinates without credentials',
    () {
      final share = JobLinks.share(41);
      expect(JobLinks.parse(share), 41);
      expect(share.toString(), 'https://thoxay.vercel.app/?job=41');
      expect(
        JobLinks.parse(Uri.parse('https://thoxay.vercel.app/?job=-1')),
        isNull,
      );
      expect(
        JobLinks.parse(Uri.parse('https://thoxay.vercel.app/?job=abc')),
        isNull,
      );
      expect(
        JobLinks.directions(fixture).queryParameters['destination'],
        '10.7769,106.7009',
      );
      expect(JobLinks.directions(fixture).queryParameters['api'], '1');
    },
  );
  testWidgets('save and unsave job reflects confirmed backend state', (
    tester,
  ) async {
    final api = DiscoveryApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FavoriteButton(api: api, id: 41)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu công trình'));
    await tester.pumpAndSettle();
    expect(api.saved, isTrue);
    expect(find.text('Đã lưu'), findsOneWidget);
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(api.saved, isFalse);
    api.dispose();
  });
  testWidgets('QR contains only the public job link', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: JobUtilities(job: fixture)),
      ),
    );
    await tester.tap(find.text('Chia sẻ'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await tester.tap(find.text('Sao chép link'));
    await tester.pumpAndSettle();
    expect(copied, 'https://thoxay.vercel.app/?job=41');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
  testWidgets('opening authenticated shared link loads correct job', (
    tester,
  ) async {
    final api = DiscoveryApi();
    await tester.pumpWidget(
      MaterialApp(
        home: SharedJobGate(
          api: api,
          jobId: 41,
          child: const Scaffold(body: Text('Trang chủ')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Công trình được chia sẻ'), findsOneWidget);
    expect(find.text('Nhà phố QA'), findsOneWidget);
    expect(find.text('Ứng tuyển'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('empty saved list offers a discovery action', (tester) async {
    final api = DiscoveryApi();
    await tester.pumpWidget(
      MaterialApp(home: SavedScreen(api: api, worker: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lưu cơ hội phù hợp với bạn'), findsOneWidget);
    expect(find.text('Khám phá ngay'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('edit job preloads fields and submits existing map coordinates', (
    tester,
  ) async {
    final api = DiscoveryApi();
    await tester.pumpWidget(MaterialApp(home: ContractorHomeScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sửa công trình'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sửa công trình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa công trình'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa công trình'), findsOneWidget);
    expect(find.text('Nhà phố QA'), findsWidgets);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(api.updated?['latitude'], 10.7769);
    expect(api.updated?['longitude'], 106.7009);
    expect(api.updated?['title'], 'Nhà phố QA');
    expect(api.updated?['startsOn'], isNotNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
