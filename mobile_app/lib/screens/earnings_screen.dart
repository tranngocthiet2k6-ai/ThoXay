import '../widgets/content_skeleton.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import 'wallet_screen.dart';
import '../widgets/earnings_chart.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _period = 'MONTH';
  DateTime _date = DateTime.now();
  Earnings? _data;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await widget.api.earnings(_period, _date);
      if (mounted) setState(() => _data = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() => _date = date);
      await _load();
    }
  }

  Widget _part(String title, int value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: Text(
        money(value.toDouble()),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thu nhập'),
      actions: [
        IconButton(
          tooltip: 'Mở ví',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WalletScreen(api: widget.api),
            ),
          ),
          icon: const Icon(Icons.account_balance_wallet_outlined),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Thành quả từ đôi bàn tay',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'DAY', label: Text('Ngày')),
              ButtonSegment(value: 'WEEK', label: Text('Tuần')),
              ButtonSegment(value: 'MONTH', label: Text('Tháng')),
            ],
            selected: {_period},
            onSelectionChanged: _busy
                ? null
                : (s) {
                    setState(() => _period = s.first);
                    _load();
                  },
          ),
          TextButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              'Chọn ngày: ${MaterialLocalizations.of(context).formatShortDate(_date)}',
            ),
          ),
          if (_busy && _data == null) const ContentSkeleton(compact: true),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
          if (_data case final data? when !_busy && _error == null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thu nhập đã nhận',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      money(data.total.toDouble()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${data.jobs} công trình đã thanh toán',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${MaterialLocalizations.of(context).formatShortDate(data.from)} – ${MaterialLocalizations.of(context).formatShortDate(data.to)} · Giờ Việt Nam',
            ),
            const SizedBox(height: 16),
            EarningsChart(data: data),
            _part('Tiền công', data.base, Icons.construction_outlined),
            _part('Tiền tip', data.tip, Icons.volunteer_activism_outlined),
            _part('Tiền thưởng', data.bonus, Icons.stars_outlined),
            if (data.jobs == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Chưa có thu nhập trong kỳ này. Thu nhập sẽ xuất hiện khi chủ thầu thanh toán công trình đã hoàn thành.',
                ),
              ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Chỉ thống kê tiền công, tip và thưởng đã được thanh toán vào ví. Tiền nạp và chuyển ký quỹ không tính là thu nhập.',
            style: TextStyle(color: Colors.blueGrey, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
