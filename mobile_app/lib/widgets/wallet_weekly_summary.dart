import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'earnings_timeline_chart.dart';
import 'figma_components.dart';

class WalletWeeklySummary extends StatefulWidget {
  const WalletWeeklySummary({
    super.key,
    required this.api,
    required this.entries,
    required this.hasMore,
    required this.worker,
  });
  final ApiService api;
  final List<WalletEntry> entries;
  final bool hasMore, worker;
  @override
  State<WalletWeeklySummary> createState() => _WalletWeeklySummaryState();
}

class _WalletWeeklySummaryState extends State<WalletWeeklySummary> {
  Earnings? _earnings;
  DateTime _date = DateTime.now();
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WalletWeeklySummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.length != widget.entries.length ||
        oldWidget.entries.firstOrNull?.id != widget.entries.firstOrNull?.id) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!widget.worker) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await widget.api.earnings('WEEK', _date);
      if (mounted) setState(() => _earnings = data);
    } catch (_) {
      /* This optional panel never hides a confirmed wallet balance. */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.worker && _earnings == null) {
      return FigmaCard(
        child: Text(
          _loading
              ? 'Đang tải thu nhập tuần…'
              : 'Chưa tải được thống kê tuần. Kéo xuống để thử lại.',
          style: TextStyle(color: AppPalette.of(context).muted),
        ),
      );
    }
    final now = _date, date = DateTime(now.year, now.month, now.day);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final days = widget.worker
        ? _earnings!.days
        : List.generate(7, (index) {
            final day = monday.add(Duration(days: index));
            final total = widget.entries
                .where((e) {
                  final d = e.createdAt.toLocal();
                  return e.kind == 'JOB_PAYMENT' &&
                      DateTime(d.year, d.month, d.day) == day;
                })
                .fold<int>(0, (sum, e) => sum + e.amount);
            return EarningsDay.fromJson({
              'date': day.toIso8601String().split('T').first,
              'base': total,
              'tip': 0,
              'bonus': 0,
              'total': total,
            });
          });
    final total = widget.worker
        ? _earnings!.total
        : days.fold<int>(0, (sum, day) => sum + day.total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.worker ? 'Thu nhập tuần' : 'Chi trả tuần',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Chọn tuần thống kê',
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null && mounted) {
                  setState(() {
                    _date = date;
                    _earnings = null;
                    _loading = true;
                  });
                  await _load();
                }
              },
            ),
          ],
        ),
        Text(
          'Tuần ${monday.day}/${monday.month} – ${monday.add(const Duration(days: 6)).day}/${monday.add(const Duration(days: 6)).month}',
          style: TextStyle(fontSize: 11, color: AppPalette.of(context).muted),
        ),
        const SizedBox(height: 8),
        Text(
          money(total.toDouble()),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (!widget.worker)
          Text(
            widget.hasMore
                ? 'Tổng từ các giao dịch đã tải; tải thêm lịch sử để có đầy đủ.'
                : 'Tiền công đã thanh toán trong tuần từ sổ giao dịch.',
            style: TextStyle(fontSize: 11, color: AppPalette.of(context).muted),
          ),
        const SizedBox(height: 8),
        EarningsTimelineChart(days: days),
      ],
    );
  }
}
