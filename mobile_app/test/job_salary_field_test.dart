import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/job_salary_field.dart';

void main() {
  testWidgets('salary can be entered or selected with a visible VND unit', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forRole('ROLE_CONTRACTOR'),
        home: Scaffold(body: JobSalaryField(controller: controller)),
      ),
    );
    expect(find.text('VND'), findsOneWidget);
    final presets = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(presets, hasLength(5));
    for (final chip in presets) {
      final label = (chip.label as Text).data!;
      expect(label, endsWith(' VND'));
      expect(
        int.parse(label.split(' ').first.replaceAll('.', '')),
        greaterThan(200000),
      );
    }
    await tester.tap(find.text('400.000 VND'));
    await tester.pump();
    expect(controller.text, '400000');
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '400.000 VND'))
          .selected,
      isTrue,
    );
    await tester.enterText(find.byType(TextFormField), '375000');
    await tester.pump();
    expect(JobSalaryField.validAmount(controller.text), 375000);
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .any((c) => c.selected),
      isFalse,
    );
    await tester.tap(find.text('250.000 VND'));
    await tester.pump();
    expect(JobSalaryField.validAmount(controller.text), 250000);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'salary boundaries show validation without overflow on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_CONTRACTOR'),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: form,
                child: JobSalaryField(controller: controller),
              ),
            ),
          ),
        ),
      );
      for (final input in ['', '0', '199999', '200000', '1000000001']) {
        await tester.enterText(find.byType(TextFormField), input);
        expect(form.currentState!.validate(), isFalse);
        await tester.pumpAndSettle();
        expect(find.textContaining('Lương phải trên 200.000'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      for (final input in ['200001', '375000', '1000000000']) {
        await tester.enterText(find.byType(TextFormField), input);
        expect(form.currentState!.validate(), isTrue);
        await tester.pumpAndSettle();
        expect(find.textContaining('Lương phải trên 200.000'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
