import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/screens/location_picker_screen.dart';

import 'worker_home_test.dart' show WorkerApi, FixedLocation;

import 'maps_test.dart' show UnavailableLocation;

void main() {
  testWidgets(
    'picker obtains GPS and permits map selection when GPS is denied',
    (tester) async {
      for (final location in [FixedLocation(), UnavailableLocation()]) {
        await tester.pumpWidget(
          MaterialApp(home: LocationPickerScreen(location: location)),
        );
        await tester.pumpAndSettle();
        if (location is FixedLocation) {
          expect(find.textContaining('10.776900'), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Dùng vị trí đã chọn'),
                )
                .onPressed,
            isNotNull,
          );
        } else {
          expect(
            find.textContaining('Bạn vẫn có thể chạm bản đồ'),
            findsOneWidget,
          );
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Dùng vị trí đã chọn'),
                )
                .onPressed,
            isNull,
          );
        }
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets(
    'worker location action opens a map instead of coordinate fields',
    (tester) async {
      final api = WorkerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerHomeScreen(api: api, location: FixedLocation()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bộ lọc vị trí'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Chọn vị trí tìm việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Chọn vị trí tìm việc'));
      await tester.pumpAndSettle();
      expect(find.byType(LocationPickerScreen), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Vĩ độ'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Kinh độ'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
