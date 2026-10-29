import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/widgets/adaptive_viewport.dart';

void main() {
  testWidgets('desktop frame bounds pages and reports its actual local width', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final width in [320.0, 768.0, 1920.0]) {
      tester.view.physicalSize = Size(width, 900);
      double? local;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AdaptiveViewport(child: child!),
          home: Builder(
            builder: (context) {
              local = MediaQuery.sizeOf(context).width;
              return const Scaffold(body: Text('Adaptive page'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final expected = width > 1120 ? 1120.0 : width;
      expect(tester.getSize(find.byType(Scaffold)).width, expected);
      expect(local, expected);
      expect(tester.takeException(), isNull);
    }
  });
}
