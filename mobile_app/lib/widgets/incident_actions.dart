import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import '../screens/incidents_screen.dart';
import 'incident_report_dialog.dart';
import 'app_snack_bar.dart';

class IncidentActions extends StatelessWidget {
  const IncidentActions({super.key, required this.api, required this.job});
  final ApiService api;
  final Job job;
  Future<void> _sos(BuildContext context) async {
    final detail = await showDialog<IncidentDetail>(
      context: context,
      builder: (_) => IncidentReportDialog(api: api, job: job, sos: true),
    );
    if (detail != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: Text(
            'Đã gửi SOS #${detail.incident.id} tới Admin. Theo dõi trong Sự cố đã gửi.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: () => _sos(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        icon: const Icon(Icons.sos),
        label: const Text('SOS tới Admin'),
      ),
      TextButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IncidentsScreen(api: api, job: job),
          ),
        ),
        icon: const Icon(Icons.report_outlined),
        label: const Text('Sự cố / tranh chấp'),
      ),
    ],
  );
}
