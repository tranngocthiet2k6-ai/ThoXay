import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/widgets/job_schedule_picker.dart';

void main() {
  Future<void> showPicker(
    WidgetTester tester,
    DateTimeRange initial, {
    bool enabled = true,
    ValueChanged<DateTimeRange>? onChanged,
  }) async {
    var value = initial;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => JobSchedulePicker(
                value: value,
                enabled: enabled,
                onChanged: (range) {
                  setState(() => value = range);
                  onChanged?.call(range);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('separate date choices clamp the end and allow cancellation', (
    tester,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month + 2, 10);
    DateTimeRange? selected;
    await showPicker(
      tester,
      DateTimeRange(start: start, end: start),
      onChanged: (range) => selected = range,
    );
    await tester.tap(find.byKey(const ValueKey('job-start-date')));
    await tester.pumpAndSettle();
    expect(find.text('Chọn ngày bắt đầu làm'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(CalendarDatePicker),
        matching: find.text('15'),
      ),
    );
    await tester.tap(find.text('Chọn ngày'));
    await tester.pumpAndSettle();
    final expected = DateTime(start.year, start.month, 15);
    expect(selected?.start, expected);
    expect(selected?.end, expected);

    await tester.tap(find.byKey(const ValueKey('job-end-date')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .firstDate,
      expected,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(CalendarDatePicker),
        matching: find.text('18'),
      ),
    );
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(selected?.end, expected);

    await tester.tap(find.byKey(const ValueKey('job-end-date')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CalendarDatePicker),
        matching: find.text('18'),
      ),
    );
    await tester.tap(find.text('Chọn ngày'));
    await tester.pumpAndSettle();
    expect(selected?.end, DateTime(start.year, start.month, 18));
    expect(find.textContaining('· 4 ngày làm'), findsOneWidget);
  });

  testWidgets('quick durations include both dates across a year boundary', (
    tester,
  ) async {
    final start = DateTime(DateTime.now().year + 1, 12, 30);
    DateTimeRange? selected;
    await showPicker(
      tester,
      DateTimeRange(start: start, end: start),
      onChanged: (range) => selected = range,
    );
    await tester.tap(find.text('Làm 3 ngày'));
    await tester.pumpAndSettle();
    expect(selected?.start, start);
    expect(selected?.end, DateTime(start.year + 1, 1, 1));
    expect(find.textContaining('· 3 ngày làm'), findsOneWidget);
    await tester.tap(find.text('Làm 1 ngày'));
    await tester.pumpAndSettle();
    expect(selected?.end, start);
    expect(find.textContaining('· 1 ngày làm'), findsOneWidget);
    // Existing jobs beyond the usual one-year window can still be edited.
    await tester.tap(find.byKey(const ValueKey('job-start-date')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'tomorrow shortcut adjusts a one-day job and respects disabled state',
    (tester) async {
      final today = DateUtils.dateOnly(DateTime.now());
      DateTimeRange? selected;
      await showPicker(
        tester,
        DateTimeRange(start: today, end: today),
        onChanged: (range) => selected = range,
      );
      await tester.tap(find.text('Bắt đầu ngày mai'));
      await tester.pumpAndSettle();
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      expect(selected?.start, tomorrow);
      expect(selected?.end, tomorrow);
      expect(find.textContaining('· 1 ngày làm'), findsOneWidget);

      await showPicker(tester, selected!, enabled: false);
      for (final chip in tester.widgetList<ChoiceChip>(
        find.byType(ChoiceChip),
      )) {
        expect(chip.onSelected, isNull);
      }
      for (final button in tester.widgetList<OutlinedButton>(
        find.byType(OutlinedButton),
      )) {
        expect(button.onPressed, isNull);
      }
    },
  );
}
