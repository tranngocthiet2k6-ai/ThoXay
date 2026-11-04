import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'portfolio_uploads.dart';

class ApplicantEvidence extends StatefulWidget {
  const ApplicantEvidence({
    super.key,
    required this.api,
    required this.workerId,
  });
  final ApiService api;
  final int workerId;
  @override
  State<ApplicantEvidence> createState() => _ApplicantEvidenceState();
}

class _ApplicantEvidenceState extends State<ApplicantEvidence> {
  WorkerProfile? _worker;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final worker = await widget.api.workerProfile(widget.workerId);
      if (mounted) setState(() => _worker = worker);
    } catch (_) {
      /* Keep the server-confirmed application and decision controls usable. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = _worker;
    if (worker == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${worker.experienceYears} năm kinh nghiệm · ${worker.skills.join(" · ")}',
          style: TextStyle(fontSize: 12, color: AppPalette.of(context).muted),
        ),
        const SizedBox(height: 8),
        Text(
          '${worker.reputationScore}/100 uy tín · ${worker.completedJobs} việc hoàn thành',
          style: TextStyle(
            color: AppPalette.of(context).successStrong,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        PortfolioUploads(
          api: widget.api,
          ownerId: widget.workerId,
          editable: false,
          compact: true,
        ),
      ],
    );
  }
}
