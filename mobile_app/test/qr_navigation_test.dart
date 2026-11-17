import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/screens/contractor_home_screen.dart';

import 'worker_home_test.dart' show WorkerApi;
import 'contractor_home_test.dart' show ContractorApi;

void main() {
  for (final worker in [true, false]) {
    testWidgets('QR is the central in-place destination for worker=$worker', (
      tester,
    ) async {
      final api = WorkerApi()..online = false;
      final contractor = ContractorApi();
      await tester.pumpWidget(
        MaterialApp(
          home: worker
              ? WorkerHomeScreen(api: api)
              : ContractorHomeScreen(api: contractor),
        ),
      );
      await tester.pumpAndSettle();
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.length, 5);
      expect((bar.destinations[2] as NavigationDestination).label, 'Quét QR');
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Quét QR'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      expect(find.text('Quét mã QR'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
      contractor.dispose();
    });
  }
}
