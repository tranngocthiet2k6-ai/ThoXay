import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/widgets/figma_job_map.dart';

import 'worker_home_test.dart' show WorkerApi, FixedLocation;

class _MapApi extends WorkerApi {
  int searches = 0;
  @override
  Future<List<Job>> nearby(
    double lat,
    double lng,
    double radius, {
    String? jobType,
    String sort = 'DISTANCE',
  }) async {
    searches++;
    return super.nearby(lat, lng, radius, jobType: jobType, sort: sort);
  }
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'expanded map has a visible exit without opening filters at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = _MapApi();
        await tester.pumpWidget(
          MaterialApp(
            home: WorkerHomeScreen(api: api, location: FixedLocation()),
          ),
        );
        await tester.pumpAndSettle();
        final search = find.byType(TextField).first;
        await tester.ensureVisible(search);
        await tester.enterText(search, 'nhà phố');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Xem bản đồ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xem bản đồ'));
        await tester.pumpAndSettle();
        final exit = find.byKey(const ValueKey('exit-job-map'));
        expect(exit.hitTestable(), findsOneWidget);
        expect(find.byType(JobMapPreview), findsNothing);
        await tester.tap(exit);
        await tester.pumpAndSettle();
        expect(find.byType(JobMapPreview), findsOneWidget);
        expect(tester.widget<TextField>(search).controller!.text, 'nhà phố');
        expect(api.searches, 1);
        expect(
          Navigator.of(tester.element(find.byType(WorkerHomeScreen))).canPop(),
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }
}
