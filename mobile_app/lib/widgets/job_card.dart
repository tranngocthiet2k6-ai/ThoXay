import 'package:flutter/material.dart';

import '../models/models.dart';
import 'call_button.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.action,
    this.canContactContractor = false,
  });
  final Job job;
  final Widget action;
  final bool canContactContractor;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: Text(job.jobType),
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              if (job.distanceKm != null)
                Text(
                  '${job.distanceKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${money(job.salaryPerDay)} / ngày',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(job.address),
          const SizedBox(height: 6),
          Text(
            'Cần ${job.requiredWorkers} thợ · ${statusLabel(job.status)}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: () => showJobDetails(
                  context,
                  job,
                  canContactContractor: canContactContractor,
                ),
                child: const Text('Xem chi tiết'),
              ),
              action,
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> showJobDetails(
  BuildContext context,
  Job job, {
  bool canContactContractor = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .75,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(
            '${money(job.salaryPerDay)} / ngày',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text('${job.jobType} · Cần ${job.requiredWorkers} người'),
          const SizedBox(height: 16),
          Text(job.address),
          const SizedBox(height: 24),
          Text(
            job.description.isEmpty
                ? 'Chủ thầu chưa bổ sung mô tả.'
                : job.description,
          ),
          const Divider(height: 40),
          Text('Chủ thầu: ${job.contractorName}'),
          const SizedBox(height: 8),
          if (canContactContractor && job.contractorPhone != null)
            CallButton(phone: job.contractorPhone!, label: 'Gọi chủ thầu'),
          const SizedBox(height: 16),
          Text(statusLabel(job.status)),
        ],
      ),
    ),
  ),
);
