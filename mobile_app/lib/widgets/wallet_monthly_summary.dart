import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'figma_components.dart';

/// Compares complete calendar months from the ledger API, never sample balances.
class WalletMonthlySummary extends StatefulWidget {
  const WalletMonthlySummary({
    super.key,
    required this.api,
    required this.entries,
    required this.hasMore,
    required this.hidden,
  });
  final ApiService api;
  final List<WalletEntry> entries;
  final bool hasMore, hidden;
  @override
  State<WalletMonthlySummary> createState() => _WalletMonthlySummaryState();
}

class _WalletMonthlySummaryState extends State<WalletMonthlySummary> {
  Earnings? _current, _previous;
  bool _loading = true;
  final _now = DateTime.now().toUtc().add(const Duration(hours: 7));
  bool get _worker => widget.api.session?.role != 'ROLE_CONTRACTOR';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WalletMonthlySummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.firstOrNull?.id != widget.entries.firstOrNull?.id ||
        oldWidget.entries.length != widget.entries.length) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!_worker) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await Future.wait([
        widget.api.earnings('MONTH', _now),
        widget.api.earnings('MONTH', DateTime(_now.year, _now.month - 1, 1)),
      ]);
      if (mounted) {
        setState(() {
          _current = data[0];
          _previous = data[1];
        });
      }
    } catch (_) {
      /* Optional statistics must not hide the confirmed balance. */
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final total = _worker
        ? _current?.total
        : widget.entries
              .where((e) {
                final day = e.createdAt.toUtc().add(const Duration(hours: 7));
                return e.kind == 'JOB_PAYMENT' &&
                    day.year == _now.year &&
                    day.month == _now.month;
              })
              .fold<int>(0, (sum, e) => sum + e.amount);
    final previous = _previous?.total;
    final growth = previous == null || previous == 0 || total == null
        ? null
        : (total - previous) * 100 / previous;
    return FigmaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _worker ? 'Thu nhập tháng này' : 'Chi phí tháng này',
                  style: TextStyle(fontSize: 11, color: palette.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.hidden
                      ? '••••••'
                      : total == null
                      ? (_loading ? 'Đang tải…' : 'Chưa tải được thống kê')
                      : money(total.toDouble()),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_worker && widget.hasMore)
                  Text(
                    'Theo giao dịch đã tải',
                    style: TextStyle(fontSize: 10, color: palette.muted),
                  ),
              ],
            ),
          ),
          if (growth != null && !widget.hidden)
            Tooltip(
              message: 'So với tổng thu nhập tháng trước',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: growth >= 0 ? palette.successSoft : palette.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${growth >= 0 ? '↗ +' : '↘ '}${growth.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: growth >= 0 ? palette.successStrong : palette.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
