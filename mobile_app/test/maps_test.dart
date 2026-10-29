import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/location_picker_screen.dart';
import 'package:tho_xay_mobile/services/location_service.dart';
import 'package:tho_xay_mobile/widgets/jobs_map.dart';
import 'package:tho_xay_mobile/widgets/loading_jobs.dart';

class MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

// Decode the in-memory image on the real event loop before waiting for loading
// animations. A continuous shimmer is expected while the codec is still pending.
Future<void> settleMap(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  if (find.byType(FlutterMap).evaluate().isNotEmpty) {
    await tester.runAsync(
      () => precacheImage(
        MemoryImage(TileProvider.transparentImage),
        tester.element(find.byType(FlutterMap).first),
      ),
    );
  }
  for (
    var frame = 0;
    frame < 50 && find.byType(ShimmerSurface).evaluate().isNotEmpty;
    frame++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Job job(int id, double lat, double lng) => Job(
  id: id,
  contractorId: 2,
  contractorName: 'Thầu',
  contractorPhone: null,
  title: 'Công trình $id',
  description: '',
  jobType: 'Thợ chính',
  salaryPerDay: 500000,
  address: 'TP.HCM',
  latitude: lat,
  longitude: lng,
  requiredWorkers: 1,
  status: 'OPEN',
);

void main() {
  testWidgets('map picker requires a tap and returns the selected coordinate', (
    tester,
  ) async {
    GeoPoint? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await Navigator.of(context).push<GeoPoint>(
                  MaterialPageRoute(
                    builder: (_) =>
                        LocationPickerScreen(tileProvider: MemoryTiles()),
                  ),
                );
              },
              child: const Text('Mở bản đồ'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở bản đồ'));
    await settleMap(tester);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Dùng vị trí đã chọn'),
          )
          .onPressed,
      isNull,
    );
    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(30, 30),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await settleMap(tester);
    expect(find.text('Chưa chọn vị trí'), findsNothing);
    await tester.tap(find.text('Dùng vị trí đã chọn'));
    await settleMap(tester);
    expect(selected, isNotNull);
    expect(selected!.latitude, inInclusiveRange(-85, 85));
    expect(selected!.longitude, inInclusiveRange(-180, 180));
  });
  testWidgets('jobs map shows pins and opens the selected job', (tester) async {
    Job? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 380,
            child: JobsMap(
              center: const GeoPoint(10.7769, 106.7009),
              jobs: [job(1, 10.779, 106.705), job(2, 10.773, 106.698)],
              tileProvider: MemoryTiles(),
              onJobTap: (value) => chosen = value,
            ),
          ),
        ),
      ),
    );
    await settleMap(tester);
    expect(find.byKey(const ValueKey('job-marker-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-marker-2')), findsOneWidget);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    expect(find.text('500.000 đ'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('job-marker-2')));
    await settleMap(tester);
    expect(chosen?.id, 2);
  });
  testWidgets('changing filtered results recenters to the new pins', (
    tester,
  ) async {
    Widget view(GeoPoint center, List<Job> jobs) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 380,
          child: JobsMap(
            center: center,
            jobs: jobs,
            tileProvider: MemoryTiles(),
            onJobTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      view(const GeoPoint(10.7769, 106.7009), [job(1, 10.778, 106.702)]),
    );
    await settleMap(tester);
    await tester.pumpWidget(
      view(const GeoPoint(21.0285, 105.8542), [job(2, 21.03, 105.855)]),
    );
    await settleMap(tester);
    expect(find.byKey(const ValueKey('job-marker-1')), findsNothing);
    expect(find.byKey(const ValueKey('job-marker-2')), findsOneWidget);
  });
}
