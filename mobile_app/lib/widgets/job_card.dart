import 'package:flutter/material.dart';

import '../models/models.dart';
import 'call_button.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.action,
    this.canContactContractor = false,
    this.detailsActionBuilder,
  });
  final Job job;
  final Widget action;
  final bool canContactContractor;
  final WidgetBuilder? detailsActionBuilder;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: JobStatusBadge(status: job.status)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${money(job.salaryPerDay)} / ngày',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  job.jobType == 'Thợ chính'
                      ? Icons.engineering_outlined
                      : Icons.handyman_outlined,
                  size: 18,
                ),
                label: Text(job.jobType),
                backgroundColor: job.jobType == 'Thợ chính'
                    ? Theme.of(context).colorScheme.primaryContainer
                    : const Color(0xffffedd5),
                side: BorderSide.none,
              ),
              if (job.distanceKm != null)
                Chip(
                  avatar: const Icon(Icons.near_me_outlined, size: 18),
                  label: Text('${job.distanceKm!.toStringAsFixed(1)} km'),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _JobInfo(icon: Icons.location_on_outlined, label: job.address),
          const SizedBox(height: 8),
          _JobInfo(
            icon: Icons.groups_outlined,
            label: 'Cần ${job.requiredWorkers} thợ',
          ),
          const Divider(height: 32),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.apartment_outlined, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.contractorName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: () => showJobDetails<void>(
                  context,
                  job,
                  canContactContractor: canContactContractor,
                  action: action,
                  actionBuilder: detailsActionBuilder,
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

class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'OPEN' => const Color(0xff047857),
      'IN_PROGRESS' => const Color(0xff1d4ed8),
      'COMPLETED' => const Color(0xff6d28d9),
      _ => const Color(0xffb91c1c),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JobInfo extends StatelessWidget {
  const _JobInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: const Color(0xff64748b)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Color(0xff64748b), height: 1.5),
        ),
      ),
    ],
  );
}

Future<T?> showJobDetails<T>(
  BuildContext context,
  Job job, {
  bool canContactContractor = false,
  Widget? action,
  WidgetBuilder? actionBuilder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 880),
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .8,
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JobStatusBadge(status: job.status),
                const SizedBox(height: 16),
                Text(
                  job.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  '${money(job.salaryPerDay)} / ngày',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text('${job.jobType} · Cần ${job.requiredWorkers} người'),
                const SizedBox(height: 16),
                _JobInfo(icon: Icons.location_on_outlined, label: job.address),
                const SizedBox(height: 24),
                const Text(
                  'Thông tin công việc',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  job.description.isEmpty
                      ? 'Chủ thầu chưa bổ sung mô tả.'
                      : job.description,
                ),
                const Divider(height: 40),
                Text('Chủ thầu: ${job.contractorName}'),
                if (canContactContractor && job.contractorPhone != null) ...[
                  const SizedBox(height: 8),
                  CallButton(
                    phone: job.contractorPhone!,
                    label: 'Gọi chủ thầu',
                  ),
                ],
              ],
            ),
          ),
        ),
        if (action != null || actionBuilder != null)
          Container(
            key: const ValueKey('job-detail-actions'),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xffe2e8f0))),
            ),
            child: SafeArea(
              top: false,
              child: actionBuilder?.call(context) ?? action!,
            ),
          ),
      ],
    ),
  ),
);
