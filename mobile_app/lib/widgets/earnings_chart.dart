import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/wallet.dart';

/// Composition of confirmed income in the selected API period, without
/// inventing daily amounts that are not included in the aggregate response.
class EarningsChart extends StatelessWidget {
  const EarningsChart({super.key, required this.data});
  final Earnings data;
  @override
  Widget build(BuildContext context) {
    final values = [data.base, data.tip, data.bonus];
    final max = math.max(1, values.reduce(math.max));
    final colors = [
      Theme.of(context).colorScheme.primary,
      const Color(0xff0284c7),
      const Color(0xffa16207),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cơ cấu thu nhập trong kỳ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tiền công, tip và thưởng đã thanh toán',
              style: TextStyle(color: Color(0xff64748b)),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Semantics(
                      label:
                          '${['Tiền công', 'Tiền tip', 'Tiền thưởng'][i]} ${money(values[i].toDouble())}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Tooltip(
                              message: money(values[i].toDouble()),
                              child: Container(
                                key: ValueKey('income-bar-$i'),
                                height: 144,
                                alignment: Alignment.bottomCenter,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xffcbd5e1),
                                    ),
                                  ),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: .6,
                                  heightFactor: values[i] / max,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colors[i],
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ['Công', 'Tip', 'Thưởng'][i],
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
