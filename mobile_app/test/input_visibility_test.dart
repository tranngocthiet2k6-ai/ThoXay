import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/figma_design.dart';
import 'package:tho_xay_mobile/widgets/job_salary_field.dart';
import 'package:tho_xay_mobile/widgets/job_schedule_picker.dart';

double _contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
  testWidgets(
    'salary and schedule choices paint visible borders in every state',
    (tester) async {
      final salary = TextEditingController(text: '450000');
      addTearDown(salary.dispose);
      final today = DateUtils.dateOnly(DateTime.now());
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.forRole('ROLE_CONTRACTOR', brightness: brightness),
            home: FigmaScreenTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      JobSalaryField(controller: salary),
                      JobSchedulePicker(
                        value: DateTimeRange(start: today, end: today),
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final chip in find.byType(ChoiceChip).evaluate()) {
          final ink = tester.widget<Ink>(
            find
                .descendant(
                  of: find.byWidget(chip.widget),
                  matching: find.byType(Ink),
                )
                .first,
          );
          final decoration = ink.decoration! as ShapeDecoration;
          final border = (decoration.shape as OutlinedBorder).side;
          expect(border.style, BorderStyle.solid);
          expect(
            _contrast(border.color, decoration.color!),
            greaterThanOrEqualTo(3),
          );
        }
        for (final key in ['job-start-date', 'job-end-date']) {
          final material = tester.widget<Material>(
            find
                .descendant(
                  of: find.byKey(ValueKey(key)),
                  matching: find.byType(Material),
                )
                .first,
          );
          final border = (material.shape! as OutlinedBorder).side;
          final background = Theme.of(tester.element(find.byKey(ValueKey(key))))
              .colorScheme
              .surface;
          expect(_contrast(border.color, background), greaterThanOrEqualTo(3));
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'empty text and dropdown fields have visible boundaries in every theme',
    (tester) async {
      for (final role in ['ROLE_WORKER', 'ROLE_CONTRACTOR']) {
        for (final mode in ['light', 'dark', 'outdoor']) {
          for (final screenTheme in [false, true]) {
            final fields = Scaffold(
              body: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Loại thợ'),
                    items: const [
                      DropdownMenuItem(
                        value: 'worker',
                        child: Text('Thợ chính'),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.forRole(
                  role,
                  brightness: mode == 'dark'
                      ? Brightness.dark
                      : Brightness.light,
                  outdoor: mode == 'outdoor',
                ),
                home: screenTheme ? FigmaScreenTheme(child: fields) : fields,
              ),
            );
            await tester.pumpAndSettle();
            for (final decorator in tester.widgetList<InputDecorator>(
              find.byType(InputDecorator),
            )) {
              final decoration = decorator.decoration;
              final border = decoration.enabledBorder!;
              final reason = '$role / $mode / screenTheme=$screenTheme';
              expect(border.isOutline, isTrue, reason: reason);
              expect(
                border.borderSide.style,
                BorderStyle.solid,
                reason: reason,
              );
              final background = decoration.fillColor!;
              final painted = Color.alphaBlend(
                border.borderSide.color,
                background,
              );
              expect(
                _contrast(painted, background),
                greaterThanOrEqualTo(3),
                reason: reason,
              );
            }
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
}
