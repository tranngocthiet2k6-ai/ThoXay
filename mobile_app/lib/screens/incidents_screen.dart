import '../widgets/design_motion.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_report_dialog.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key, required this.api, this.job});
  final ApiService api;
  final Job? job;
  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  List<IncidentItem> _items = [];
  bool _loading = true, _more = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.myIncidents(
        jobId: widget.job?.id,
        beforeId: more && _items.isNotEmpty ? _items.last.id : null,
      );
      if (mounted) {
        setState(() {
          _items = more ? [..._items, ...data.items] : data.items;
          _more = data.hasMore;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _report() async {
    final detail = await showDialog<IncidentDetail>(
      context: context,
      builder: (_) => IncidentReportDialog(api: widget.api, job: widget.job!),
    );
    if (detail != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              IncidentDetailScreen(api: widget.api, id: detail.incident.id),
        ),
      );
      if (mounted) await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sự cố đã gửi')),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.job != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.job!.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _loading ? null : _report,
                        icon: const Icon(Icons.report_outlined),
                        label: const Text('Báo cáo sự cố / tranh chấp'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading && _items.isEmpty) const ContentSkeleton(),
            if (_error != null) ...[
              Text(_error!),
              TextButton(
                onPressed: () => _load(),
                child: const Text('Thử lại'),
              ),
            ],
            if (!_loading && _items.isEmpty && _error == null)
              EmptyState(
                icon: Icons.health_and_safety_outlined,
                title: 'Chưa có báo cáo sự cố',
                message: 'Báo cáo của bạn và cập nhật từ Admin sẽ xuất hiện tại đây.',
                action: TextButton(
                  onPressed: () => _load(),
                  child: const Text('Làm mới danh sách'),
                ),
              ),
            for (final item in _items)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    item.type == 'SOS' ? Icons.sos : Icons.report_outlined,
                    color: item.type == 'SOS'
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('${incidentType(item.type)} · #${item.id}'),
                  subtitle: Text(
                    '${item.jobTitle}\n${incidentStatus(item.status)} · ${incidentTime(item.createdAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            IncidentDetailScreen(api: widget.api, id: item.id),
                      ),
                    );
                    if (mounted) await _load();
                  },
                ),
              ),
            if (_more)
              TextButton(
                onPressed: _loading ? null : () => _load(more: true),
                child: const Text('Tải báo cáo cũ hơn'),
              ),
          ],
        ),
      ),
    ),
  );
}

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({super.key, required this.api, required this.id});
  final ApiService api;
  final int id;
  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  IncidentDetail? _detail;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.incident(widget.id);
      if (mounted) setState(() => _detail = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Báo cáo #${widget.id}'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Làm mới báo cáo',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            if (_loading) const ContentSkeleton(),
            if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
            if (_detail case final d?) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        incidentType(d.incident.type),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(d.incident.jobTitle),
                      const SizedBox(height: 12),
                      Chip(label: Text(incidentStatus(d.incident.status))),
                      const SizedBox(height: 12),
                      Text(d.incident.description),
                      const SizedBox(height: 16),
                      Text(incidentTime(d.incident.createdAt)),
                      if (d.incident.adminNote.isNotEmpty) ...[
                        const Divider(height: 32),
                        Text(
                          'Cập nhật từ Admin',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(d.incident.adminNote),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '30 cập nhật gần nhất',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final entry in d.history)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(incidentStatus(entry.status)),
                    subtitle: Text(
                      '${entry.note}\n${incidentTime(entry.createdAt)}',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
