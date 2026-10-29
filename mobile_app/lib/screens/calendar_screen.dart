import 'package:flutter/material.dart';

import '../models/scheduling.dart';
import '../services/api_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/design_motion.dart';
import '../widgets/empty_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime.now();
  List<CalendarEntry> _events = [];
  bool _busy = false;
  int _generation = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final entries = await widget.api.calendar(
        DateTime(_month.year, _month.month),
        DateTime(_month.year, _month.month + 1, 0),
      );
      if (mounted && generation == _generation) {
        setState(() => _events = entries);
      }
    } on ApiException catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _block() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (range == null || !mounted) return;
    try {
      await widget.api.blockCalendar(
        range.start,
        range.end,
        'Bận việc cá nhân',
      );
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    }
  }

  Future<void> _remove(CalendarEntry entry) async {
    try {
      await widget.api.removeCalendarBlock(entry.id);
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch làm việc')),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SectionIntro(
              title: 'Chủ động ngày làm',
              subtitle: 'Công trình đã được nhận và ngày bận của riêng bạn. Hệ thống chặn lịch trùng khi duyệt.',
            ),
            CalendarDatePicker(
              initialDate: _month,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              onDateChanged: (_) {},
              onDisplayedMonthChanged: (m) {
                setState(() => _month = m);
                _load();
              },
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _block,
              icon: const Icon(Icons.event_busy),
              label: const Text('Đánh dấu ngày bận'),
            ),
            const SizedBox(height: 16),
            if (_busy) const ContentSkeleton(compact: true),
            if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
            if (!_busy && _error == null && _events.isEmpty)
              const EmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'Tháng này còn trống',
                message: 'Lịch công trình có ngày cụ thể sẽ xuất hiện sau khi được duyệt.',
              ),
            for (final event in _events)
              Card(
                child: ListTile(
                  leading: Icon(
                    event.kind == 'JOB' ? Icons.construction : Icons.event_busy,
                  ),
                  title: Text(event.title),
                  subtitle: Text('${isoDay(event.from)} – ${isoDay(event.to)}'),
                  trailing: event.kind == 'BLOCKED'
                      ? IconButton(
                          tooltip: 'Xóa ngày bận',
                          onPressed: _busy ? null : () => _remove(event),
                          icon: const Icon(Icons.delete_outline),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
