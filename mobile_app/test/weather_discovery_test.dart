import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/weather.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/widgets/job_weather_panel.dart';

import 'contractor_home_test.dart' show ContractorApi;
import 'worker_home_test.dart' show WorkerApi, FixedLocation;

const report = AreaWeather(
  available: true,
  stale: false,
  temperature: 28,
  code: 3,
);

class WeatherJobsApi extends ContractorApi {
  final latitudes = <double>[];
  @override
  Future<AreaWeather> weather(double lat, double lng) async {
    latitudes.add(lat);
    return report;
  }
}

class WeatherWorkerApi extends WorkerApi {
  @override
  Future<AreaWeather> weather(double lat, double lng) async => report;
}

class NoWeatherGps extends LocationService {
  @override
  Future<GeoPoint> currentPosition() async =>
      throw const LocationFailure('Không lấy được GPS');
}

Job site(int id, String title, String address, double lat) => Job(
  id: id,
  contractorId: 2,
  contractorName: 'QA',
  contractorPhone: null,
  title: title,
  description: '',
  jobType: 'Thợ chính',
  salaryPerDay: 350000,
  address: address,
  latitude: lat,
  longitude: 106,
  requiredWorkers: 1,
  status: 'IN_PROGRESS',
);

void main() {
  testWidgets(
    'weather keeps a manual area choice when phone GPS is unavailable',
    (tester) async {
      final api = WeatherWorkerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeContent(
            api: api,
            location: NoWeatherGps(),
            tab: 0,
            onTabChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thời tiết nơi tìm việc'), findsOneWidget);
      expect(find.text('Chọn khu vực'), findsOneWidget);
      expect(
        find.text('Chọn khu vực trên bản đồ để xem thời tiết.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'weather is visible and job search matches the actual address on a phone',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final api = WeatherJobsApi();
      final jobs = [
        site(1, 'Xây tường', 'Hà Nội', 10),
        site(2, 'Lát gạch', 'Đà Nẵng', 16),
      ];
      Job selected = jobs.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: JobWeatherPanel(
                  api: api,
                  jobs: jobs,
                  selected: selected,
                  onChanged: (job) => setState(() => selected = job),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('28°C · Nhiều mây').hitTestable(), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      await tester.tap(find.text('Chọn / tìm công trình'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Đà Nẵng');
      await tester.pumpAndSettle();
      expect(find.text('Lát gạch'), findsOneWidget);
      expect(find.text('Xây tường'), findsNothing);
      await tester.tap(find.text('Lát gạch'));
      await tester.pumpAndSettle();
      expect(selected.id, 2);
      expect(api.latitudes, [10, 16]);
      expect(find.text('Lát gạch · Đà Nẵng'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'contractor weather is directly available without two hidden expansion levels',
    (tester) async {
      final api = WeatherJobsApi();
      await tester.pumpWidget(
        MaterialApp(home: ContractorHomeContent(api: api)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(JobWeatherPanel), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(api.latitudes, isNotEmpty);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('worker weather is independent of advanced job filters', (
    tester,
  ) async {
    final api = WeatherWorkerApi();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerHomeContent(
          api: api,
          location: FixedLocation(),
          tab: 0,
          onTabChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thời tiết nơi tìm việc'), findsOneWidget);
    expect(find.text('Đổi khu vực'), findsOneWidget);
    expect(find.text('28°C · Nhiều mây'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
