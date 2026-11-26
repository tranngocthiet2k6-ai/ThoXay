import 'package:flutter/material.dart';

/// Two explicit dates keep posting a job understandable without range gestures.
class JobSchedulePicker extends StatelessWidget {
  const JobSchedulePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final DateTimeRange value;
  final ValueChanged<DateTimeRange> onChanged;
  final bool enabled;

  String _date(DateTime day) =>
      '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';

  int get _days => value.duration.inDays + 1;

  void _startOn(DateTime day) => onChanged(
    DateTimeRange(start: day, end: value.end.isBefore(day) ? day : value.end),
  );

  Future<void> _pick(BuildContext context, {required bool start}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final limit = today.add(const Duration(days: 365));
    final day = await showDatePicker(
      context: context,
      initialDate: start ? value.start : value.end,
      firstDate: start ? today : value.start,
      lastDate: value.end.isAfter(limit) ? value.end : limit,
      helpText: start ? 'Chọn ngày bắt đầu làm' : 'Chọn ngày kết thúc làm',
      cancelText: 'Hủy',
      confirmText: 'Chọn ngày',
      fieldLabelText: start ? 'Ngày bắt đầu' : 'Ngày kết thúc',
      fieldHintText: 'dd/mm/yyyy',
    );
    if (day == null || !context.mounted) return;
    if (start) {
      _startOn(day);
    } else {
      onChanged(DateTimeRange(start: value.start, end: day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Thời gian làm việc', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        const Text('Chọn ngày bắt đầu, sau đó chọn ngày kết thúc.'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Bắt đầu hôm nay'),
              selected: DateUtils.isSameDay(value.start, today),
              onSelected: enabled ? (_) => _startOn(today) : null,
            ),
            ChoiceChip(
              label: const Text('Bắt đầu ngày mai'),
              selected: DateUtils.isSameDay(value.start, tomorrow),
              onSelected: enabled ? (_) => _startOn(tomorrow) : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('job-start-date'),
          onPressed: enabled ? () => _pick(context, start: true) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ngày bắt đầu'),
                      Text(
                        _date(value.start),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('job-end-date'),
          onPressed: enabled ? () => _pick(context, start: false) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.event_available_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ngày kết thúc'),
                      Text(
                        _date(value.end),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Làm trong ngày: chọn ngày kết thúc trùng ngày bắt đầu.'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in [1, 3, 7])
              ChoiceChip(
                label: Text('Làm $days ngày'),
                selected: _days == days,
                onSelected: enabled
                    ? (_) => onChanged(
                        DateTimeRange(
                          start: value.start,
                          end: DateTime(
                            value.start.year,
                            value.start.month,
                            value.start.day + days - 1,
                          ),
                        ),
                      )
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            'Từ ${_date(value.start)} đến ${_date(value.end)} · $_days ngày làm',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text('Tính cả ngày bắt đầu và ngày kết thúc.'),
      ],
    );
  }
}
