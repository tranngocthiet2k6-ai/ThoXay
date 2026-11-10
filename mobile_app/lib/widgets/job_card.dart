import '../services/location_service.dart';
import 'figma_job_map.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'design_motion.dart';
import 'call_button.dart';
import 'job_utilities.dart';
import '../services/api_service.dart';
import 'figma_components.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.action,
    this.canContactContractor = false,
    this.detailsActionBuilder,
    this.api,
    this.primaryAction,
    this.previewOnly = false,
    this.onTap,
  });
  final ApiService? api;
  final Job job;
  final Widget action;
  final Widget? primaryAction;
  final bool previewOnly;
  final VoidCallback? onTap;
  final bool canContactContractor;
  final WidgetBuilder? detailsActionBuilder;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = Theme.of(context).colorScheme.primary;
    void open() {
      if (onTap != null) {
        onTap!();
      } else {
        showJobDetails<void>(
          context,
          job,
          api: api,
          canContactContractor: canContactContractor,
          action: action,
          actionBuilder: detailsActionBuilder,
        );
      }
    }

    Widget detailsLink() => TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 40),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: open,
      icon: const Icon(Icons.arrow_outward_rounded, size: 14),
      label: const Text('Xem chi tiết'),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DesignReveal(
        child: InkWell(
          onTap: previewOnly ? open : null,
          borderRadius: BorderRadius.circular(16),
          child: DesignSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (job.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.soft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${job.distanceKm!.toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 11, color: palette.muted),
                        ),
                      )
                    else
                      JobStatusBadge(status: job.status),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      job.contractorName,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.successStrong,
                      ),
                    ),
                    if (job.contractorVerified) const KycBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  previewOnly
                      ? job.address
                      : '${job.address} · ${job.jobType} · ${job.requiredWorkers} thợ',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: palette.muted),
                ),
                if (previewOnly)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.jobType,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (job.startsOn != null && !previewOnly)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${MaterialLocalizations.of(context).formatShortDate(job.startsOn!)}${job.endsOn == null ? "" : " – ${MaterialLocalizations.of(context).formatShortDate(job.endsOn!)}"}',
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: money(job.salaryPerDay),
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: -.6,
                            ),
                          ),
                          TextSpan(
                            text: '/ngày',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (previewOnly) detailsLink() else primaryAction ?? action,
                  ],
                ),
                if (primaryAction != null)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    title: const Text(
                      'Quản lý công trình',
                      style: TextStyle(fontSize: 12),
                    ),
                    children: [action],
                  ),
                if (!previewOnly)
                  Align(alignment: Alignment.centerLeft, child: detailsLink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'OPEN' => AppPalette.of(context).successStrong,
      'IN_PROGRESS' => AppPalette.of(context).blue,
      'COMPLETED' => AppPalette.of(context).purple,
      _ => AppPalette.of(context).errorStrong,
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
      Icon(icon, size: 18, color: AppPalette.of(context).muted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: TextStyle(color: AppPalette.of(context).muted, height: 1.5),
        ),
      ),
    ],
  );
}

Future<T?> showJobDetails<T>(
  BuildContext context,
  Job job, {
  ApiService? api,
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
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
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
                if (job.attendanceRequired)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Chấm công GPS/QR và ảnh nghiệm thu là căn cứ thanh toán ngày công.',
                    ),
                  ),
                const SizedBox(height: 16),
                _JobInfo(icon: Icons.location_on_outlined, label: job.address),
                const SizedBox(height: 24),
                Text(
                  'Thông tin công việc',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  job.description.isEmpty
                      ? 'Chủ thầu chưa bổ sung mô tả.'
                      : job.description,
                ),
                const Divider(height: 40),
                Text('Chủ thầu: ${job.contractorName}'),
                const SizedBox(height: 16),
                JobMapPreview(
                  center: GeoPoint(job.latitude, job.longitude),
                  jobs: [job],
                  onJobTap: (_) => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Địa điểm công trình"),
                      content: JobUtilities(job: job, api: api),
                    ),
                  ),
                ),
                if (job.contractorVerified)
                  const Chip(
                    avatar: Icon(Icons.verified, size: 18),
                    label: Text('Chủ thầu đã xác thực CCCD'),
                  ),
                if (job.startsOn != null)
                  Text(
                    'Lịch: ${job.startsOn!.toIso8601String().split('T').first} – ${job.endsOn!.toIso8601String().split('T').first}',
                  ),
                const SizedBox(height: 16),
                JobUtilities(job: job, api: api),
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
            decoration: BoxDecoration(
              color: AppPalette.of(context).surface,
              border: Border(
                top: BorderSide(color: AppPalette.of(context).border),
              ),
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
