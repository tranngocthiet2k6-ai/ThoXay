import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/widgets/job_application_actions.dart';

void main() {
  testWidgets(
    'sticky job actions fit compact screens and large text with one primary action',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var applies = 0, offers = 0;
      for (final width in [320.0, 390.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(16),
                child: JobApplicationActions(
                  onApply: () => applies++,
                  onNegotiate: () => offers++,
                  onChat: null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(find.byKey(const ValueKey('job-detail-chat')))
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Thương lượng giá'));
        await tester.tap(find.text('Ứng tuyển ngay'));
      }
      expect(applies, 3);
      expect(offers, 3);
    },
  );
}
