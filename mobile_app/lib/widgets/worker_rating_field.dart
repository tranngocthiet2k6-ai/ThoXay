import 'package:flutter/material.dart';

import '../models/models.dart';

class WorkerRatingField extends StatelessWidget {
  const WorkerRatingField({
    super.key,
    required this.application,
    required this.value,
    required this.onChanged,
    this.locked = false,
  });
  final JobApplication application;
  final int? value;
  final ValueChanged<int>? onChanged;
  final bool locked;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        application.workerName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(
        'Mã thợ #${application.workerId}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Wrap(
        children: [
          for (int stars = 1; stars <= 5; stars++)
            IconButton(
              tooltip: 'Chấm $stars sao cho ${application.workerName}',
              visualDensity: VisualDensity.compact,
              onPressed: locked || onChanged == null
                  ? null
                  : () => onChanged!(stars),
              icon: Icon(
                (value ?? 0) >= stars ? Icons.star : Icons.star_border,
                color: Colors.amber.shade800,
              ),
            ),
        ],
      ),
      Text(
        locked
            ? 'Đã chốt đánh giá · ${value ?? application.jobRating ?? 0}/5 sao'
            : value == null
            ? 'Chưa chọn điểm'
            : '$value / 5 sao',
      ),
    ],
  );
}
