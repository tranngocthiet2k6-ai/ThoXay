import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/job_card.dart';
import '../widgets/job_application_actions.dart';
import '../widgets/wage_offer_sheet.dart';
import 'chat_screen.dart';
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
  bool _canChat = false;
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
      bool canChat = false;
      if (widget.api.session?.role == 'ROLE_WORKER') {
        final applications = await widget.api.workerApplications();
        applied = applications.any((a) => a.job.id == j.id);
        canChat = applications.any(
          (a) => a.job.id == j.id && a.status == 'ACCEPTED',
        );
      }
      if (mounted) {
        setState(() {
          _job = j;
          _applied = applied;
          _canChat = canChat;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply({bool negotiate = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final j = _job!;
      if (j.startsOn == null) {
        await widget.api.apply(j.id);
      } else {
        WageOffer? offer;
        if (negotiate) {
          offer = await showWageOffer(context);
          if (offer == null || !mounted) return;
        }
        if (!mounted) return;
        final proposal = await showWorkProposal(
          context,
          widget.api,
          j,
          proposedRate: offer?.rate,
          note: offer?.note ?? '',
        );
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

  Future<void> _details() => showJobDetails<void>(
    context,
    _job!,
    api: widget.api,
    canContactContractor: _canChat,
    actionBuilder: widget.api.session?.role != 'ROLE_WORKER'
        ? null
        : (sheetContext) => JobApplicationActions(
            applied: _applied,
            busy: _busy || _job!.status != 'OPEN',
            onApply: () {
              Navigator.pop(sheetContext);
              _apply();
            },
            onNegotiate: _job!.startsOn == null
                ? null
                : () {
                    Navigator.pop(sheetContext);
                    _apply(negotiate: true);
                  },
            onChat: !_canChat
                ? null
                : () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(
                          api: widget.api,
                          job: _job!,
                          peerId: _job!.contractorId,
                          peerName: _job!.contractorName,
                        ),
                      ),
                    );
                  },
          ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Công trình được chia sẻ')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
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
              canContactContractor: _canChat,
              previewOnly: true,
              onTap: _details,
              action: const SizedBox.shrink(),
            ),
        ],
      ),
    ),
  );
}
