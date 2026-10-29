import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/job_card.dart';
import '../widgets/work_commitment.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/app_snack_bar.dart';

class SharedJobGate extends StatefulWidget {
  const SharedJobGate({
    super.key,
    required this.api,
    required this.child,
    this.jobId,
  });
  final ApiService api;
  final Widget child;
  final int? jobId;
  @override
  State<SharedJobGate> createState() => _SharedJobGateState();
}

class _SharedJobGateState extends State<SharedJobGate> {
  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SharedJobScreen(api: widget.api, jobId: widget.jobId!),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class SharedJobScreen extends StatefulWidget {
  const SharedJobScreen({super.key, required this.api, required this.jobId});
  final ApiService api;
  final int jobId;
  @override
  State<SharedJobScreen> createState() => _SharedJobScreenState();
}

class _SharedJobScreenState extends State<SharedJobScreen> {
  Job? _job;
  String? _error;
  bool _loading = true, _busy = false, _applied = false;
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
      final j = await widget.api.fetchJob(widget.jobId);
      bool applied = false;
      if (widget.api.session?.role == 'ROLE_WORKER') {
        applied = (await widget.api.workerApplications()).any(
          (a) => a.job.id == j.id,
        );
      }
      if (mounted) {
        setState(() {
          _job = j;
          _applied = applied;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final j = _job!;
      if (j.startsOn == null) {
        await widget.api.apply(j.id);
      } else {
        final proposal = await showWorkProposal(context, widget.api, j);
        if (proposal == null || !mounted) return;
        await widget.api.applyWithTerms(j.id, proposal);
      }
      if (mounted) {
        setState(() => _applied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: const Text('Đã gửi đơn ứng tuyển.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Công trình được chia sẻ')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          if (_loading) const ContentSkeleton(),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          if (!_loading && _job != null)
            JobCard(
              api: widget.api,
              job: _job!,
              canContactContractor: _applied,
              action: widget.api.session?.role == 'ROLE_WORKER'
                  ? FilledButton.icon(
                      onPressed:
                          _busy ||
                              _applied ||
                              !['OPEN', 'IN_PROGRESS'].contains(_job!.status)
                          ? null
                          : _apply,
                      icon: const Icon(Icons.handshake_outlined),
                      label: Text(
                        _busy
                            ? 'Đang gửi…'
                            : _applied
                            ? 'Đã ứng tuyển'
                            : 'Ứng tuyển',
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    ),
  );
}
