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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xffe3eae6)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff1b4637).withValues(alpha: .045),
          blurRadius: 22,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _JobBadge(
                label: job.jobType,
                icon: job.jobType == 'Thợ chính'
                    ? Icons.engineering_outlined
                    : Icons.handyman_outlined,
                color: job.jobType == 'Thợ chính'
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xff95510a),
                background: job.jobType == 'Thợ chính'
                    ? Theme.of(context).colorScheme.primaryContainer
                    : const Color(0xfffff2df),
              ),
              if (job.distanceKm != null)
                _JobBadge(
                  label: '${job.distanceKm!.toStringAsFixed(1)} km',
                  icon: Icons.near_me_outlined,
                  color: const Color(0xff416a92),
                  background: const Color(0xffeef4fb),
                ),
              _JobBadge(
                label: statusLabel(job.status),
                icon: job.status == 'COMPLETED'
                    ? Icons.task_alt
                    : Icons.circle_outlined,
                color: job.status == 'CANCELLED'
                    ? const Color(0xffae3d40)
                    : const Color(0xff51685e),
                background: job.status == 'CANCELLED'
                    ? const Color(0xffffeeee)
                    : const Color(0xfff0f4f2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            job.title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                Text(
                  '${money(job.salaryPerDay)} / ngày',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _JobInfo(icon: Icons.location_on_outlined, label: job.address),
          const SizedBox(height: 8),
          _JobInfo(
            icon: Icons.groups_outlined,
            label: 'Cần ${job.requiredWorkers} thợ · ${job.contractorName}',
          ),
          const Divider(height: 30),
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

class _JobBadge extends StatelessWidget {
  const _JobBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });
  final String label;
  final IconData icon;
  final Color color, background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _JobInfo extends StatelessWidget {
  const _JobInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: const Color(0xff6b8075)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Color(0xff61756b), height: 1.4),
        ),
      ),
    ],
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
