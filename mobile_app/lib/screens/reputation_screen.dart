import 'package:flutter/material.dart';

import '../models/reputation.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';

class ReputationScreen extends StatefulWidget {
  const ReputationScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<ReputationScreen> createState() => _ReputationScreenState();
}

class _ReputationScreenState extends State<ReputationScreen> {
  final _items = <ReputationEntry>[];
  bool _loading = false, _hasMore = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.api.reputationHistory(
        beforeId: more && _items.isNotEmpty ? _items.last.id : null,
      );
      if (mounted) {
        setState(() {
          if (!more) _items.clear();
          _items.addAll(page.items);
          _hasMore = page.hasMore;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch sử uy tín')),
    body: RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Điểm khởi đầu 100. Hoàn thành công trình +2 điểm (tối đa 100), hủy việc đang làm -15 điểm (tối thiểu 0).',
          ),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: () => _load(), child: const Text('Thử lại')),
          ],
          if (!_loading && _error == null && _items.isEmpty)
            const EmptyState(
              title: 'Hành trình uy tín của bạn',
              message: 'Các thay đổi điểm từ công việc sẽ được ghi lại ở đây.',
            ),
          for (final entry in _items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.type == 'COMPLETED'
                          ? 'Hoàn thành công trình'
                          : 'Hủy việc đang làm',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(entry.jobTitle),
                    const SizedBox(height: 8),
                    Text(
                      '${entry.delta >= 0 ? '+' : ''}${entry.delta} điểm · Uy tín sau thay đổi: ${entry.scoreAfter}/100',
                      style: TextStyle(
                        color: entry.delta < 0
                            ? Colors.red.shade700
                            : const Color(0xff176b52),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      MaterialLocalizations.of(context)
                          .formatFullDate(entry.createdAt.toLocal()),
                    ),
                  ],
                ),
              ),
            ),
          if (_hasMore)
            TextButton(
              onPressed: _loading ? null : () => _load(more: true),
              child: const Text('Tải lịch sử cũ'),
            ),
        ],
      ),
    ),
  );
}
