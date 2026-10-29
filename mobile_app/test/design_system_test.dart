import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/widgets/adaptive_viewport.dart';
import 'package:tho_xay_mobile/widgets/ranking_podium.dart';
import 'package:tho_xay_mobile/models/reputation.dart';

void main() {
  testWidgets(
    'podium places winner above and between runners up on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int? opened;
      final workers = List.generate(
        3,
        (i) => WorkerRank.fromJson({
          'rank': i + 1,
          'workerId': i + 10,
          'fullName': 'Người thợ hạng ${i + 1}',
          'workerTier': 'DIAMOND',
          'reputationScore': 100,
          'rating': 5,
          'completedJobs': 30,
          'verified': true,
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RankingPodium(
                workers: workers,
                onTap: (w) => opened = w.workerId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final winner = tester.getRect(find.byKey(const ValueKey('podium-1')));
      final second = tester.getRect(find.byKey(const ValueKey('podium-2')));
      final third = tester.getRect(find.byKey(const ValueKey('podium-3')));
      expect(winner.top, lessThan(second.top));
      expect(winner.top, lessThan(third.top));
      expect(winner.center.dx, greaterThan(second.center.dx));
      expect(winner.center.dx, lessThan(third.center.dx));
      await tester.tap(find.byKey(const ValueKey('podium-1')));
      expect(opened, 10);
      expect(tester.takeException(), isNull);
    },
  );
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
