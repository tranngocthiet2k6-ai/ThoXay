import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/widgets/job_staffing_fields.dart';

void main() {
  testWidgets(
    'trade selection validates quantities, totals and stepper bounds',
    (tester) async {
      final form = GlobalKey<FormState>();
      final skilled = TextEditingController(text: '1');
      final helpers = TextEditingController(text: '1');
      var skilledSelected = true;
      var helpersSelected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Form(
                key: form,
                child: JobStaffingFields(
                  skilledController: skilled,
                  helpersController: helpers,
                  skilledSelected: skilledSelected,
                  helpersSelected: helpersSelected,
                  onSkilledChanged: (value) =>
                      setState(() => skilledSelected = value),
                  onHelpersChanged: (value) =>
                      setState(() => helpersSelected = value),
                ),
              ),
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isTrue);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Giảm số Thợ chính',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Tăng số Phụ hồ',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Tăng số Thợ chính'));
      expect(skilled.text, '2');
      await tester.pump();
      await tester.tap(find.byTooltip('Giảm số Thợ chính'));
      expect(skilled.text, '1');
      await tester.enterText(
        find.byKey(const ValueKey('quantity-Thợ chính')),
        '',
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.enterText(
        find.byKey(const ValueKey('quantity-Thợ chính')),
        '0',
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.enterText(
        find.byKey(const ValueKey('quantity-Thợ chính')),
        '10000',
      );
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Tăng số Thợ chính',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Phụ hồ'));
      await tester.pump();
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Tổng số thợ không quá 10.000'), findsOneWidget);
      await tester.tap(find.text('Thợ chính'));
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      await tester.tap(find.text('Phụ hồ'));
      await tester.pump();
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Chọn ít nhất một loại thợ'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      skilled.dispose();
      helpers.dispose();
    },
  );
}
