import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/worker_profile.dart';
import '../models/contractor_team.dart';
import '../services/api_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/design_motion.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';
import '../widgets/call_button.dart';
import 'chat_screen.dart';
import 'worker_profile_screen.dart';

/// A contractor's address book and private groups, distinct from workers' crews.
class ContractorTeamScreen extends StatefulWidget {
  const ContractorTeamScreen({super.key, required this.api, this.onDiscover});
  final ApiService api;
  final VoidCallback? onDiscover;
  @override
  State<ContractorTeamScreen> createState() => _ContractorTeamScreenState();
}

class _ContractorTeamScreenState extends State<ContractorTeamScreen> {
  List<WorkerProfile> _workers = [];
  List<ContractorGroup> _groups = [];
  List<TeamContact> _contacts = [];
  List<Job> _jobs = [];
  bool _loading = true, _busy = false;
  String? _error;
  String _query = '';
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
      // Record.wait wraps API failures in ParallelWaitError. Future.wait keeps
      // the original ApiException so the retry state below can handle it.
      final results = await Future.wait<Object>([
        widget.api.savedWorkers(),
        widget.api.contractorGroups(),
        widget.api.teamContacts(),
        widget.api.contractorJobs(),
      ]);
      if (mounted) {
        setState(() {
          _workers = results[0] as List<WorkerProfile>;
          _groups = results[1] as List<ContractorGroup>;
          _contacts = results[2] as List<TeamContact>;
          _jobs = results[3] as List<Job>;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final field = TextEditingController();
    final form = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo nhóm thợ mới'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: field,
            autofocus: true,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Tên nhóm',
              hintText: 'Ví dụ: Đội xây tô',
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Nhập tên nhóm' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, field.text.trim());
              }
            },
            child: const Text('Tạo nhóm'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    field.dispose();
    if (name != null && mounted) {
      await _run(() => widget.api.createContractorGroup(name));
    }
  }

  Future<T?> _choose<T>(
    String title,
    List<T> values,
    String Function(T) label,
  ) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  if (values.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Chưa có mục phù hợp.'),
                    ),
                  for (final value in values)
                    ListTile(
                      title: Text(label(value)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(context, value),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _addToGroup(WorkerProfile worker) async {
    final group = await _choose(
      'Thêm ${worker.fullName} vào nhóm',
      _groups.where((g) => !g.members.any((m) => m.id == worker.id)).toList(),
      (g) => g.name,
    );
    if (group != null && mounted) {
      await _run(
        () => widget.api.contractorGroupMember(group.id, worker.id, true),
      );
    }
  }

  Future<void> _addMember(ContractorGroup group) async {
    final worker = await _choose(
      'Chọn thợ đã lưu',
      _workers.where((w) => !group.members.any((m) => m.id == w.id)).toList(),
      (w) => w.fullName,
    );
    if (worker != null && mounted) {
      await _run(
        () => widget.api.contractorGroupMember(group.id, worker.id, true),
      );
    }
  }

  Future<void> _invite(List<WorkerProfile> workers) async {
    if (workers.isEmpty || _busy) return;
    final job = await _choose(
      'Mời tham gia công trình',
      _jobs.where((j) => j.canRecruit).toList(),
      (j) => j.title,
    );
    if (job == null || !mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi lời mời công trình?'),
        content: Text(
          'Mời ${workers.length} thợ xem “${job.title}”. Mỗi thợ cần tự đọc cam kết và ứng tuyển; lời mời chưa phải quyết định nhận việc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi lời mời'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _run(() async {
        await widget.api.inviteTeamToJob(
          job.id,
          workers.map((w) => w.id).toList(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar(
              content: const Text(
                'Đã gửi lời mời. Chờ thợ tự xác nhận ứng tuyển.',
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _chat(WorkerProfile worker) async {
    final contexts = _contacts.where((c) => c.workerId == worker.id).toList();
    final contact = contexts.length == 1
        ? contexts.first
        : await _choose(
            'Chọn công trình để liên lạc',
            contexts,
            (c) => c.job.title,
          );
    if (contact != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            api: widget.api,
            job: contact.job,
            peerId: worker.id,
            peerName: worker.fullName,
          ),
        ),
      );
    }
  }

  Future<void> _deleteGroup(ContractorGroup group) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhóm thợ?'),
        content: Text(
          'Xóa nhóm “${group.name}”. Thợ đã lưu và các công trình vẫn được giữ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa nhóm'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _run(() => widget.api.deleteContractorGroup(group.id));
    }
  }

  Widget _worker(WorkerProfile worker) {
    final contact = _contacts.where((c) => c.workerId == worker.id).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(
                api: widget.api,
                name: worker.fullName,
                path: worker.avatarUrl,
                size: 44,
              ),
              title: Text(
                worker.fullName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                '${worker.verified ? 'Đã KYC · ' : ''}${worker.rating.toStringAsFixed(1)} ★ · ${worker.experienceYears} năm kinh nghiệm',
              ),
              trailing: IconButton(
                tooltip: 'Xem hồ sơ ${worker.fullName}',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => WorkerProfileScreen(
                      api: widget.api,
                      workerId: worker.id,
                    ),
                  ),
                ),
              ),
            ),
            if (worker.skills.isNotEmpty)
              Text(
                worker.skills.join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy || contact == null
                      ? null
                      : () => _chat(worker),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Nhắn tin'),
                ),
                if (contact != null)
                  CallButton(phone: contact.phoneNumber, label: 'Gọi điện'),
                TextButton.icon(
                  onPressed: _busy ? null : () => _addToGroup(worker),
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('Thêm vào nhóm'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _invite([worker]),
                  child: const Text('Mời công trình'),
                ),
              ],
            ),
            if (contact == null)
              Text(
                'Liên lạc trực tiếp được mở khi đơn ứng tuyển đã được duyệt.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _group(ContractorGroup group) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${group.name} · ${group.members.length} thợ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Xóa nhóm ${group.name}',
                onPressed: _busy ? null : () => _deleteGroup(group),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (group.members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Thêm thợ đã lưu để xây dựng đội ngũ.'),
            ),
          for (final worker in group.members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(
                api: widget.api,
                name: worker.fullName,
                path: worker.avatarUrl,
                size: 36,
              ),
              title: Text(worker.fullName),
              onTap: () => _chat(worker),
              trailing: IconButton(
                tooltip: 'Bỏ ${worker.fullName} khỏi nhóm',
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => widget.api.contractorGroupMember(
                          group.id,
                          worker.id,
                          false,
                        ),
                      ),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _addMember(group),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Thêm thợ'),
              ),
              TextButton(
                onPressed: _busy || group.members.isEmpty
                    ? null
                    : () => _invite(group.members),
                child: const Text('Mời cả nhóm vào công trình'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: 'Thợ đã lưu'),
            Tab(text: 'Nhóm thợ của tôi'),
          ],
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text(_error!)),
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            children: [
              _list([
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm tên hoặc kỹ năng thợ…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (q) =>
                      setState(() => _query = q.trim().toLowerCase()),
                ),
                const SizedBox(height: 16),
                if (!_loading && _workers.isEmpty && _error == null)
                  EmptyState(
                    title: 'Xây dựng đội ngũ tin cậy',
                    message: 'Lưu thợ từ hồ sơ ứng viên hoặc quét QR cá nhân của thợ. Mọi liên lạc vẫn theo công trình đã được duyệt.',
                    action: widget.onDiscover == null
                        ? null
                        : OutlinedButton(
                            onPressed: widget.onDiscover,
                            child: const Text('Về công trình'),
                          ),
                  ),
                for (final worker in _workers.where(
                  (w) => '${w.fullName} ${w.skills.join(' ')}'
                      .toLowerCase()
                      .contains(_query),
                ))
                  _worker(worker),
              ]),
              _list([
                FilledButton.icon(
                  onPressed: _busy || _loading ? null : _create,
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Tạo nhóm thợ mới'),
                ),
                const SizedBox(height: 16),
                if (!_loading && _groups.isEmpty && _error == null)
                  const EmptyState(
                    title: 'Đội ngũ gọn gàng, điều phối dễ dàng',
                    message: 'Tạo nhóm như Đội xây tô, Đội hoàn thiện rồi thêm các thợ đã lưu. Nhóm quản lý không tự tạo hợp đồng nhận việc.',
                  ),
                for (final group in _groups) _group(group),
              ]),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _list(List<Widget> children) => ContentFrame(
    child: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        children: [if (_loading) const ContentSkeleton(), ...children],
      ),
    ),
  );
}
