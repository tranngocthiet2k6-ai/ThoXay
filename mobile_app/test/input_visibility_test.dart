import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/figma_design.dart';

double _contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
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
