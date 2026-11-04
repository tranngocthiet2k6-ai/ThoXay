import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';

class WalletWeeklySummary extends StatefulWidget {
  const WalletWeeklySummary({
    super.key,
    required this.api,
    required this.entries,
    required this.hasMore,
    required this.worker,
    this.hidden = false,
  });
  final ApiService api;
  final List<WalletEntry> entries;
  final bool hasMore, worker;
  final bool hidden;
  @override
  State<WalletWeeklySummary> createState() => _WalletWeeklySummaryState();
}

class _WalletWeeklySummaryState extends State<WalletWeeklySummary> {
  Earnings? _earnings;
  final DateTime _date = DateTime.now().toUtc().add(const Duration(hours: 7));
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
      return Text(
        _loading
            ? 'Đang tải thu nhập tuần…'
            : 'Chưa tải được thống kê tuần. Kéo xuống để thử lại.',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                  final d = e.createdAt.toUtc().add(const Duration(hours: 7));
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
    final paid = widget.entries.where((e) {
      final day = e.createdAt.toUtc().add(const Duration(hours: 7));
      return e.kind == 'JOB_PAYMENT' &&
          !day.isBefore(monday) &&
          day.isBefore(monday.add(const Duration(days: 7)));
    }).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.insights_outlined,
              color: Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.worker ? "Thu nhập tuần này" : "Chi trả tuần này"}: ${widget.hidden ? "••••••" : "${widget.worker ? '+' : '−'}${money(total.toDouble())}"} • ${widget.worker ? '${_earnings!.jobs} công trình' : '$paid khoản công'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        if (!widget.worker && widget.hasMore)
          Text(
            'Tổng từ lịch sử đã tải; tải thêm để có đầy đủ.',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
      ],
    );
  }
}
