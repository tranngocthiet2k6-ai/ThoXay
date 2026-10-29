import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/wallet.dart';
import '../theme/app_theme.dart';

class EarningsTimelineChart extends StatefulWidget {
  const EarningsTimelineChart({super.key, required this.days});
  final List<EarningsDay> days;
  @override
  State<EarningsTimelineChart> createState() => _EarningsTimelineChartState();
}

class _EarningsTimelineChartState extends State<EarningsTimelineChart> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), days = widget.days;
    final maximum = days.fold<int>(
      1,
      (value, day) => math.max(value, day.total),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thu nhập theo ngày', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Theo ngày thanh toán · Giờ Việt Nam',
              style: TextStyle(color: AppPalette.of(context).muted),
            ),
            const SizedBox(height: 16),
            if (days.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Máy chủ chưa trả chi tiết từng ngày. Tổng thu nhập vẫn được hiển thị phía trên.',
                ),
              )
            else
              LayoutBuilder(
                builder: (context, bounds) {
                  final width = math.max(
                    56.0,
                    bounds.maxWidth / math.max(1, days.length),
                  );
                  return Scrollbar(
                    controller: _scroll,
                    thumbVisibility: days.length * width > bounds.maxWidth,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final day in days)
                            Semantics(
                              label:
                                  '${day.date.day}/${day.date.month}: ${money(day.total.toDouble())}',
                              child: Tooltip(
                                message:
                                    '${day.date.day}/${day.date.month}: ${money(day.total.toDouble())}\nCông ${money(day.base.toDouble())} · Tip ${money(day.tip.toDouble())} · Thưởng ${money(day.bonus.toDouble())}',
                                child: SizedBox(
                                  width: width,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _compact(day.total),
                                          style: theme.textTheme.labelSmall,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 144,
                                          alignment: Alignment.bottomCenter,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: AppPalette.of(context)
                                                    .border,
                                              ),
                                            ),
                                          ),
                                          child: FractionallySizedBox(
                                            widthFactor: .65,
                                            heightFactor: day.total / maximum,
                                            child: DecoratedBox(
                                              key: ValueKey(
                                                'earnings-day-${day.date.toIso8601String().split('T').first}',
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    theme.colorScheme.primary,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(6),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${day.date.day}/${day.date.month}',
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _compact(int amount) => amount >= 1000000
      ? '${(amount / 1000000).toStringAsFixed(1)}tr'
      : amount >= 1000
      ? '${(amount / 1000).round()}k'
      : '$amount';
}
