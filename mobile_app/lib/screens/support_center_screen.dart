import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/incident.dart';
import '../models/wallet.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';
import '../widgets/commercial_hero.dart';
import '../widgets/figma_components.dart';
import '../widgets/design_motion.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/incident_report_dialog.dart';
import 'incidents_screen.dart';
import 'wallet_screen.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  List<Job> _jobs = [];
  List<IncidentItem> _incidents = [];
  List<WalletEntry> _entries = [];
  List<AppNotification> _notices = [];
  Job? _job;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jobs = widget.api.session?.role == 'ROLE_CONTRACTOR'
          ? await widget.api.contractorJobs()
          : (await widget.api.workerApplications())
                .where((a) => a.status == 'ACCEPTED' || a.status == 'CANCELLED')
                .map((a) => a.job)
                .toList();
      final incidents = await widget.api.myIncidents();
      final entries = await widget.api.walletEntries();
      final notices = await widget.api.notifications();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _job =
              jobs.where((j) => j.id == _job?.id).firstOrNull ??
              jobs.firstOrNull;
          _incidents = incidents.items;
          _entries = entries.items;
          _notices = notices.items;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _report(bool sos) async {
    if (_job == null) return;
    final detail = await showDialog<IncidentDetail>(
      context: context,
      builder: (_) =>
          IncidentReportDialog(api: widget.api, job: _job!, sos: sos),
    );
    if (detail != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              IncidentDetailScreen(api: widget.api, id: detail.incident.id),
        ),
      );
      if (mounted) _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trung tâm hỗ trợ & SOS')),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const CommercialHero(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent_rounded, size: 32),
                  SizedBox(height: 16),
                  Text(
                    'An tâm mỗi ca làm',
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Theo dõi giao dịch, gửi bằng chứng và nhận phản hồi từ Admin.',
                    style: TextStyle(
                      color: Color(0xffcbd5e1),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) const ContentSkeleton(compact: true),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FigmaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Gửi yêu cầu hỗ trợ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (_jobs.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: _job?.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Công trình liên quan',
                      ),
                      items: _jobs
                          .map(
                            (j) => DropdownMenuItem(
                              value: j.id,
                              child: Text(
                                j.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(
                        () => _job = _jobs.firstWhere((j) => j.id == id),
                      ),
                    )
                  else
                    const Text(
                      'Bạn có thể gửi báo cáo khi tham gia hoặc sở hữu công trình.',
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loading || _job == null
                        ? null
                        : () => _report(false),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Khiếu nại & đính kèm bằng chứng'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffb91c1c),
                      side: const BorderSide(color: Color(0xfffecaca)),
                    ),
                    onPressed: _loading || _job == null
                        ? null
                        : () => _report(true),
                    icon: const Icon(Icons.sos_rounded),
                    label: const Text('SOS · Ưu tiên an toàn'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SOS gửi cảnh báo nội bộ cho Admin, không tự gọi cứu hộ.',
                    style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thông báo công việc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final n in _notices.take(2))
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(n.title),
                  subtitle: Text(
                    n.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (!_loading && _notices.isEmpty)
              const Text('Chưa có thông báo công việc.'),
            const SizedBox(height: 24),
            const Text(
              'Biến động số dư gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (!_loading && _entries.isEmpty)
              const FigmaCard(
                child: Text(
                  'Chưa có giao dịch. Các khoản tiền thực tế sẽ xuất hiện tại đây.',
                ),
              ),
            for (final e in _entries.take(3))
              Card(
                child: ListTile(
                  leading: Icon(
                    walletEntrySign(e.kind) == '− '
                        ? Icons.north_east
                        : Icons.south_west,
                    color: walletEntrySign(e.kind) == '− '
                        ? const Color(0xffea580c)
                        : const Color(0xff059669),
                  ),
                  title: Text(walletKind(e.kind)),
                  subtitle: Text(incidentTime(e.createdAt)),
                  trailing: Text(
                    '${walletEntrySign(e.kind)}${money(e.amount.toDouble())}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WalletScreen(api: widget.api),
                ),
              ),
              child: const Text('Xem toàn bộ sổ giao dịch'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yêu cầu đã gửi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (!_loading && _incidents.isEmpty)
              const FigmaCard(
                child: Text(
                  'Chưa có yêu cầu hỗ trợ. Chúng tôi luôn sẵn sàng tiếp nhận.',
                ),
              ),
            for (final i in _incidents.take(5))
              Card(
                child: ListTile(
                  leading: Icon(
                    i.type == 'SOS' ? Icons.sos : Icons.shield_outlined,
                  ),
                  title: Text(incidentType(i.type)),
                  subtitle: Text(incidentStatus(i.status)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          IncidentDetailScreen(api: widget.api, id: i.id),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
