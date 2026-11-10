import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/widgets/bouncing_button.dart';

void main() {
  testWidgets('press scales down, cancel restores and action fires only once', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BouncingButton(
              child: FilledButton(
                onPressed: () => taps++,
                child: const Text('Tiếp tục'),
              ),
            ),
          ),
        ),
      ),
    );
    final target = find.byType(FilledButton);
    final gesture = await tester.startGesture(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .96);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(taps, 1);
    final cancelled = await tester.startGesture(tester.getCenter(target));
    await tester.pump();
    await cancelled.cancel();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('disabled and reduced motion controls never shrink', (
    tester,
  ) async {
    for (final reduced in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              body: BouncingButton(
                child: FilledButton(
                  onPressed: reduced ? () {} : null,
                  child: const Text('Thao tác'),
                ),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FilledButton)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.cancel();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('dragging a card scrolls and releases the pressed state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: Scaffold(
          body: ListView(
            children: [
              BouncingButton(
                child: SizedBox(
                  height: 120,
                  child: InkWell(onTap: () {}, child: const Text('Công trình')),
                ),
              ),
              const SizedBox(height: 1600),
            ],
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(const Offset(100, 80));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.pixels, greaterThan(0));
    final chain = <ScrollPhysics>[];
    for (
      ScrollPhysics? physics = scroll.position.physics;
      physics != null;
      physics = physics.parent
    ) {
      chain.add(physics);
    }
    expect(chain.whereType<BouncingScrollPhysics>(), isNotEmpty);
  });

  test(
    'haptic calls platform light impact and handles unsupported devices',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            return null;
          });
      AppHaptics.light();
      await Future<void>.delayed(Duration.zero);
      expect(calls.single.method, 'HapticFeedback.vibrate');
      expect(calls.single.arguments, 'HapticFeedbackType.lightImpact');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (_) async => throw PlatformException(code: 'unsupported'),
          );
      AppHaptics.light();
      await Future<void>.delayed(Duration.zero);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    },
  );
}
