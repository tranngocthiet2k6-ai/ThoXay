import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/coordinates_dialog.dart';
import '../widgets/job_card.dart';
import '../widgets/call_button.dart';
import '../widgets/chat_button.dart';
import '../widgets/job_completion_dialog.dart';
import 'profile_screen.dart';
import 'location_picker_screen.dart';
import '../widgets/loading_jobs.dart';
import '../widgets/empty_state.dart';
import '../widgets/feature_banner.dart';
import '../widgets/notification_button.dart';
import 'worker_profile_screen.dart';

class ContractorHomeScreen extends StatefulWidget {
  const ContractorHomeScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<ContractorHomeScreen> createState() => _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends State<ContractorHomeScreen> {
  List<Job> _jobs = [];
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobs = await widget.api.contractorJobs();
      if (mounted) setState(() => _jobs = jobs);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateJobDialog(api: widget.api),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã đăng công trình mới.')));
      await _refresh();
    }
  }

  Future<void> _applicants(Job job) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ApplicantsSheet(api: widget.api, job: job),
    );
    if (mounted) await _refresh();
  }

  Future<void> _complete(Job job) async {
    final completed = await showJobCompletionDialog(context, widget.api, job);
    if (completed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hoàn thành công trình và lưu đánh giá cho thợ.'),
        ),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Công trình của tôi'),
      actions: [
        NotificationButton(api: widget.api),
        IconButton(
          tooltip: 'Hồ sơ & CCCD',
          icon: const Icon(Icons.person_outline),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProfileScreen(api: widget.api),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Làm mới',
          onPressed: _loading ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: widget.api.logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width > 920
                    ? (MediaQuery.sizeOf(context).width - 880) / 2
                    : 20,
                20,
                MediaQuery.sizeOf(context).width > 920
                    ? (MediaQuery.sizeOf(context).width - 880) / 2
                    : 20,
                100,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                FeatureBanner(
                  greeting:
                      'Chào ${widget.api.session?.fullName ?? 'chủ thầu'},',
                  title: 'Tìm thợ cho công trình',
                  icon: Icons.apartment_outlined,
                  subtitle: _loading
                      ? 'Đang cập nhật công trình của bạn…'
                      : '${_jobs.length} công trình · ${_jobs.where((j) => j.status == 'OPEN').length} đang tuyển',
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!),
                    ),
                  ),
                if (_loading) const LoadingJobs(),
                if (!_loading && _jobs.isEmpty && _error == null)
                  EmptyState(
                    title: 'Công trình mới, cơ hội mới',
                    message: 'Đăng công trình đầu tiên để kết nối với người thợ quanh bạn.',
                    action: FilledButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo công trình đầu tiên'),
                    ),
                  ),
                if (!_loading)
                  for (final job in _jobs)
                    JobCard(
                      job: job,
                      action: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => _applicants(job),
                            child: const Text('Xem & duyệt thợ'),
                          ),
                          if (job.status == 'IN_PROGRESS')
                            OutlinedButton.icon(
                              onPressed: () => _complete(job),
                              icon: const Icon(Icons.task_alt),
                              label: const Text('Hoàn thành công trình'),
                            ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.add),
      label: const Text('Đăng công trình'),
    ),
  );
}

class _CreateJobDialog extends StatefulWidget {
  const _CreateJobDialog({required this.api});
  final ApiService api;
  @override
  State<_CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends State<_CreateJobDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController();
  final _salary = TextEditingController(), _address = TextEditingController();
  final _workers = TextEditingController(text: '1');
  String _type = 'Thợ chính';
  GeoPoint? _position;
  bool _busy = false, _gps = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_title, _description, _salary, _address, _workers]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _gps = true;
      _error = null;
    });
    try {
      final point = await LocationService().currentPosition();
      if (mounted) setState(() => _position = point);
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _gps = false);
    }
  }

  Future<void> _choosePosition() async {
    final point = await showCoordinatesDialog(context, current: _position);
    if (point != null && mounted) {
      setState(() {
        _position = point;
        _error = null;
      });
    }
  }

  Future<void> _chooseOnMap() async {
    final point = await Navigator.of(context).push<GeoPoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPosition: _position),
      ),
    );
    if (point != null && mounted) {
      setState(() {
        _position = point;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_position == null) {
      setState(
        () => _error = 'Chọn vị trí công trình bằng GPS hoặc nhập tọa độ.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.createJob({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'jobType': _type,
        'salaryPerDay': double.parse(_salary.text.trim()),
        'address': _address.text.trim(),
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'requiredWorkers': int.parse(_workers.text.trim()),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy && !_gps,
    child: AlertDialog(
      title: const Text('Đăng công trình mới'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  enabled: !_busy,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Tên công trình',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Nhập tên công trình'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 20000,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả công việc, giờ làm, đãi ngộ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Loại thợ'),
                  items: ['Thợ chính', 'Phụ hồ']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: _busy ? null : (t) => setState(() => _type = t!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _salary,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Lương mỗi ngày (đồng)',
                    hintText: '500000',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    return n == null || !n.isFinite || n < 1 || n > 1000000000
                        ? 'Lương từ 1 đến 1.000.000.000 đồng'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  enabled: !_busy,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ công trình',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Nhập địa chỉ công trình'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _workers,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng thợ cần tuyển',
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return n == null || n < 1 || n > 10000
                        ? 'Số thợ từ 1 đến 10.000'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  _position == null
                      ? 'Chưa chọn vị trí công trình'
                      : 'Vị trí: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy || _gps ? null : _chooseOnMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Chọn trên bản đồ'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || _gps ? null : _locate,
                      icon: const Icon(Icons.my_location),
                      label: Text(_gps ? 'Đang lấy GPS…' : 'Lấy GPS'),
                    ),
                    TextButton(
                      onPressed: _busy || _gps ? null : _choosePosition,
                      child: const Text('Nhập vị trí'),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy || _gps ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _busy || _gps ? null : _submit,
          child: Text(_busy ? 'Đang đăng…' : 'Đăng việc'),
        ),
      ],
    ),
  );
}

class _ApplicantsSheet extends StatefulWidget {
  const _ApplicantsSheet({required this.api, required this.job});
  final ApiService api;
  final Job job;
  @override
  State<_ApplicantsSheet> createState() => _ApplicantsSheetState();
}

class _ApplicantsSheetState extends State<_ApplicantsSheet> {
  List<JobApplication> _applications = [];
  bool _loading = false;
  int? _updating;
  String? _error;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.jobApplications(widget.job.id);
      if (mounted) setState(() => _applications = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(JobApplication application, String status) async {
    setState(() {
      _updating = application.id;
      _error = null;
    });
    try {
      await widget.api.updateApplication(application.id, status);
      if (mounted) await _refresh();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _updating = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _applications.where((a) => a.status == 'ACCEPTED').length;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .82,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Đã nhận $accepted / ${widget.job.requiredWorkers} thợ',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Làm mới danh sách',
                  onPressed: _loading || _updating != null ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!),
                    ),
                  ),
                if (!_loading && _applications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Chưa có thợ ứng tuyển vào công trình này.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final application in _applications)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.workerName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (application.status == 'ACCEPTED' &&
                              application.workerPhone != null)
                            CallButton(
                              phone: application.workerPhone!,
                              label: 'Gọi thợ',
                            ),
                          if (application.workerActive)
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => WorkerProfileScreen(
                                    api: widget.api,
                                    workerId: application.workerId,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.badge_outlined),
                              label: const Text('Xem hồ sơ thợ'),
                            ),
                          if (application.status == 'ACCEPTED' &&
                              application.workerActive)
                            ChatButton(
                              api: widget.api,
                              job: widget.job,
                              peerId: application.workerId,
                              peerName: application.workerName,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Đánh giá ${application.workerRating.toStringAsFixed(1)}/5 · ${application.workerVerified ? 'Đã xác thực CCCD' : 'Chưa xác thực CCCD'}',
                          ),
                          if (!application.workerActive)
                            const Text(
                              'Tài khoản đã bị khóa',
                              style: TextStyle(color: Colors.red),
                            ),
                          const SizedBox(height: 8),
                          Chip(label: Text(statusLabel(application.status))),
                          if (application.status == 'CANCELLED')
                            Text(
                              'Lý do hủy: ${application.cancellationReason ?? "Không có"}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          if (application.jobRating != null)
                            Text(
                              'Điểm công trình: ${application.jobRating}/5 ★',
                            ),
                          if (application.status == 'PENDING')
                            Wrap(
                              spacing: 12,
                              children: [
                                FilledButton(
                                  onPressed:
                                      _updating != null ||
                                          _loading ||
                                          accepted >=
                                              widget.job.requiredWorkers ||
                                          !application.workerActive
                                      ? null
                                      : () => _decide(application, 'ACCEPTED'),
                                  child: Text(
                                    _updating == application.id
                                        ? 'Đang xử lý…'
                                        : 'Nhận thợ',
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: _updating != null || _loading
                                      ? null
                                      : () => _decide(application, 'REJECTED'),
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
        ],
      ),
    );
  }
}
