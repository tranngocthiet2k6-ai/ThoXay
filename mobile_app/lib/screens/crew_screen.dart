import 'package:flutter/material.dart';

import '../models/crew.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/work_commitment.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_snack_bar.dart';

class CrewScreen extends StatefulWidget {
  const CrewScreen({super.key, required this.api, this.job});
  final ApiService api;
  final Job? job;
  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
  List<Crew> _crews = [];
  bool _loading = true, _busy = false;
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
      final crews = await widget.api.crews();
      if (mounted) setState(() => _crews = crews);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _input(
    String title,
    String label, {
    bool phone = false,
  }) async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: phone ? 15 : 100,
            keyboardType: phone ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(labelText: label),
            validator: (v) => phone
                ? !RegExp(r'^[0-9]{9,15}$').hasMatch(v?.trim() ?? '')
                      ? 'Nhập số điện thoại hợp lệ'
                      : null
                : (v?.trim().isEmpty ?? true)
                ? 'Nhập tên tổ đội'
                : null,
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
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    // Dispose after the route's closing animation has detached its text field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    return value;
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final name = await _input('Tạo tổ đội', 'Tên tổ đội');
    if (name != null && mounted) await _run(() => widget.api.createCrew(name));
  }

  Future<void> _invite(Crew c) async {
    final phone = await _input(
      'Mời thành viên',
      'Số điện thoại tài khoản thợ',
      phone: true,
    );
    if (phone != null && mounted) {
      await _run(() => widget.api.inviteCrew(c.id, phone));
    }
  }

  Future<void> _apply(Crew c) async {
    if (_busy) return;
    try {
      final p = await showWorkProposal(context, widget.api, widget.job!);
      if (p == null || !mounted) return;
      setState(() => _busy = true);
      await widget.api.crewApply(c.id, widget.job!.id, p);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(
            content: const Text(
              'Đã gửi tổ đội. Từng thành viên cần mở Đã ứng tuyển để xác nhận cam kết.',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.job == null ? 'Tổ đội của tôi' : 'Ứng tuyển theo tổ đội',
      ),
      actions: [
        IconButton(
          onPressed: _busy || _loading ? null : _create,
          tooltip: 'Tạo tổ đội',
          icon: const Icon(Icons.group_add_outlined),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.job != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Công trình: ${widget.job!.title}\nTổ trưởng chọn tổ; mỗi thợ tự đọc cam kết trước khi chủ thầu duyệt nguyên nhóm.',
                ),
              ),
            ),
          if (_loading) const ContentSkeleton(),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('Thử lại'),
            ),
          ],
          if (!_loading && _crews.isEmpty && _error == null)
            EmptyState(
              title: 'Cùng đồng đội nhận công trình',
              message: 'Tạo tổ, mời tài khoản thợ và chờ họ xác nhận. Mỗi người vẫn có chấm công và đánh giá riêng.',
              action: FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Tạo tổ đầu tiên'),
              ),
            ),
          if (!_loading)
            for (final c in _crews)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        c.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final m in c.members)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            m.status == 'CONFIRMED'
                                ? Icons.verified_user_outlined
                                : Icons.person_add_alt,
                          ),
                          title: Text(m.name),
                          subtitle: Text(
                            m.status == 'CONFIRMED'
                                ? 'Đã tham gia'
                                : m.status == 'INVITED'
                                ? 'Đang chờ xác nhận'
                                : 'Đã từ chối',
                          ),
                          trailing: m.id == c.leaderId
                              ? const Chip(label: Text('Tổ trưởng'))
                              : null,
                        ),
                      if (c.leaderId == widget.api.session?.userId) ...[
                        OutlinedButton.icon(
                          onPressed: _busy ? null : () => _invite(c),
                          icon: const Icon(Icons.person_add_outlined),
                          label: const Text('Mời thợ bằng số điện thoại'),
                        ),
                        if (widget.job != null)
                          FilledButton.icon(
                            onPressed:
                                _busy ||
                                    c.members
                                            .where(
                                              (m) => m.status == 'CONFIRMED',
                                            )
                                            .length <
                                        2
                                ? null
                                : () => _apply(c),
                            icon: const Icon(Icons.groups_outlined),
                            label: Text(
                              'Ứng tuyển ${c.members.where((m) => m.status == 'CONFIRMED').length} người',
                            ),
                          ),
                      ] else if (c.members.any(
                        (m) =>
                            m.id == widget.api.session?.userId &&
                            m.status == 'INVITED',
                      ))
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                      () =>
                                          widget.api.crewMembership(c.id, true),
                                    ),
                              child: const Text('Tham gia tổ'),
                            ),
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                      () => widget.api.crewMembership(
                                        c.id,
                                        false,
                                      ),
                                    ),
                              child: const Text('Từ chối'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
