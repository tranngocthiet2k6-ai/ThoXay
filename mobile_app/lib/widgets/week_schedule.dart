import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'figma_components.dart';

class WeekSchedule extends StatelessWidget {
  const WeekSchedule({
    super.key,
    required this.jobs,
    this.onOpenCalendar,
    this.today,
  });
  final List<Job> jobs;
  final VoidCallback? onOpenCalendar;
  final DateTime? today;
  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now(), palette = AppPalette.of(context);
    final date = DateTime(now.year, now.month, now.day);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch làm việc',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (onOpenCalendar != null)
                TextButton(
                  onPressed: onOpenCalendar,
                  child: const Text('Sửa lịch rảnh'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = monday.add(Duration(days: i)),
                          chosen = day == date;
                      final busy = jobs.any(
                        (j) =>
                            j.startsOn != null &&
                            j.endsOn != null &&
                            !day.isBefore(j.startsOn!) &&
                            !day.isAfter(j.endsOn!),
                      );
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: chosen
                              ? Theme.of(context).colorScheme.primaryContainer
                              : palette.soft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              i == 6 ? 'CN' : 'T${i + 2}',
                              style: TextStyle(
                                fontSize: 10,
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.day}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Semantics(
                              label: busy
                                  ? 'Có lịch'
                                  : 'Chưa có công trình đã nhận',
                              child: Icon(
                                Icons.circle,
                                size: 4,
                                color: busy
                                    ? Theme.of(context).colorScheme.primary
                                    : palette.border,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Lịch công trình đã nhận · Giờ Việt Nam',
            style: TextStyle(fontSize: 10, color: palette.muted),
          ),
        ],
      ),
    );
  }
}
