import 'main_shell.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/applicant_evidence.dart';
import '../widgets/figma_components.dart';
import '../widgets/figma_job_map.dart';
import '../widgets/incident_actions.dart';
import '../widgets/weather_card.dart';
import 'attendance_screen.dart';
import '../widgets/design_motion.dart';
import '../widgets/work_commitment.dart';
import '../models/scheduling.dart';
import '../widgets/app_snack_bar.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/coordinates_dialog.dart';
import '../widgets/job_card.dart';
import '../widgets/call_button.dart';
import '../widgets/chat_button.dart';
import '../widgets/job_completion_dialog.dart';
import 'location_picker_screen.dart';
import '../widgets/loading_jobs.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/hero_greeting.dart';
import '../widgets/job_search_header.dart';
import 'worker_profile_screen.dart';
import 'job_payments_screen.dart';

class ContractorHomeScreen extends StatelessWidget {
  const ContractorHomeScreen({super.key, required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) => MainShell(api: api, worker: false);
}

class ContractorHomeContent extends StatefulWidget {
  const ContractorHomeContent({super.key, required this.api});
  final ApiService api;
  @override
  State<ContractorHomeContent> createState() => _ContractorHomeContentState();
}

class _ContractorHomeContentState extends State<ContractorHomeContent> {
  List<Job> _jobs = [];
  final _search = TextEditingController();
  String _query = '', _status = '';
  int? _weatherJobId;
  Job? get _weatherJob => _jobs.isEmpty
      ? null
      : _jobs.where((j) => j.id == _weatherJobId).firstOrNull ??
            _jobs
                .where((j) => j.status == 'IN_PROGRESS' || j.status == 'OPEN')
                .firstOrNull ??
            _jobs.first;
  List<Job> get _visibleJobs =>
      _jobs
          .where(
            (j) =>
                (_status.isEmpty || j.status == _status) &&
                '${j.title} ${j.address}'.toLowerCase().contains(
                  _query.toLowerCase().trim(),
                ),
          )
          .toList()
        ..sort((a, b) {
          int priority(String status) => switch (status) {
            'IN_PROGRESS' => 0,
            'OPEN' => 1,
            'COMPLETED' => 2,
            _ => 3,
          };
          final compared = priority(a.status).compareTo(priority(b.status));
          return compared != 0 ? compared : b.id.compareTo(a.id);
        });
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(content: const Text('Đã đăng công trình mới.')),
      );
      await _refresh();
    }
  }

  Future<void> _edit(Job job) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateJobDialog(api: widget.api, job: job),
    );
    if (changed == true && mounted) await _refresh();
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
        AppSnackBar(
          content: const Text(
            'Đã hoàn thành công trình và lưu đánh giá cho thợ.',
          ),
        ),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: HeroGreeting(
                      api: widget.api,
                      title: 'Công trình của tôi',
                      subtitle: _loading
                          ? 'Đang cập nhật công trình của bạn…'
                          : '${_jobs.length} công trình · ${_jobs.where((j) => j.status == 'OPEN').length} đang tuyển',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DashboardStats(
                          values: [
                            (
                              value:
                                  '${_jobs.where((j) => j.status == "OPEN").length}',
                              label: 'Đang tuyển',
                            ),
                            (
                              value:
                                  '${_jobs.where((j) => j.status == "IN_PROGRESS").length}',
                              label: 'Đang thực hiện',
                            ),
                            (
                              value:
                                  '${_jobs.where((j) => j.status == "COMPLETED").length}',
                              label: 'Hoàn thành',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        BouncingButton(
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _create,
                            icon: const Icon(Icons.add),
                            label: const Text('Đăng công trình mới'),
                          ),
                        ),
                        if (_weatherJob != null) ...[
                          const SizedBox(height: 16),
                          JobMapPreview(
                            center: GeoPoint(
                              _weatherJob!.latitude,
                              _weatherJob!.longitude,
                            ),
                            jobs: _jobs
                                .where(
                                  (j) =>
                                      j.status == 'OPEN' ||
                                      j.status == 'IN_PROGRESS',
                                )
                                .toList(),
                            onJobTap: (j) => showJobDetails<void>(
                              context,
                              j,
                              api: widget.api,
                              action: BouncingButton(
                                child: FilledButton(
                                  onPressed: () => _applicants(j),
                                  child: const Text('Duyệt thợ'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_weatherJob != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: ExpansionTile(
                        title: const Text(
                          'Thời tiết công trình',
                          style: TextStyle(fontSize: 12),
                        ),
                        children: [
                          Column(
                            children: [
                              if (_jobs.length > 1)
                                DropdownButtonFormField<int>(
                                  initialValue: _weatherJob!.id,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Thời tiết công trình',
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
                                  onChanged: (id) =>
                                      setState(() => _weatherJobId = id),
                                ),
                              ExpansionTile(
                                title: const Text(
                                  'Thời tiết khu vực',
                                  style: TextStyle(fontSize: 12),
                                ),
                                children: [
                                  WeatherCard(
                                    api: widget.api,
                                    latitude: _weatherJob!.latitude,
                                    longitude: _weatherJob!.longitude,
                                    areaLabel: _weatherJob!.title,
                                    refreshToken: _jobs,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: JobSearchHeader(
                    height:
                        128 * MediaQuery.textScalerOf(context).scale(14) / 14,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _search,
                            onChanged: (q) => setState(() => _query = q),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Tìm công trình của bạn…',
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final status in [
                                  '',
                                  'OPEN',
                                  'IN_PROGRESS',
                                  'COMPLETED',
                                  'CANCELLED',
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(
                                        status.isEmpty
                                            ? 'Tất cả'
                                            : statusLabel(status),
                                      ),
                                      selected: status == _status,
                                      onSelected: (_) =>
                                          setState(() => _status = status),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  sliver: SliverList.list(
                    children: [
                      if (_error != null)
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_error!),
                          ),
                        ),
                      if (_loading) const LoadingJobs(),
                      if (!_loading && _visibleJobs.isEmpty && _error == null)
                        EmptyState(
                          title: 'Công trình mới, cơ hội mới',
                          message: 'Đăng công trình đầu tiên để kết nối với người thợ quanh bạn.',
                          action: BouncingButton(
                            child: FilledButton.icon(
                              onPressed: _create,
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo công trình đầu tiên'),
                            ),
                          ),
                        ),
                      if (!_loading)
                        ResponsiveJobGrid(
                          children: [
                            for (final job in _visibleJobs)
                              JobCard(
                                api: widget.api,
                                job: job,
                                primaryAction: OutlinedButton(
                                  onPressed: () => _applicants(job),
                                  child: const Text('Duyệt thợ'),
                                ),
                                action: Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => AttendanceScreen(
                                                api: widget.api,
                                                job: job,
                                              ),
                                            ),
                                          ),
                                      icon: const Icon(
                                        Icons.fact_check_outlined,
                                      ),
                                      label: const Text(
                                        'Chấm công & nghiệm thu',
                                      ),
                                    ),
                                    IncidentActions(api: widget.api, job: job),
                                    if (job.status == 'OPEN')
                                      OutlinedButton.icon(
                                        onPressed: () => _edit(job),
                                        icon: const Icon(
                                          Icons.edit_location_alt_outlined,
                                        ),
                                        label: const Text('Sửa công trình'),
                                      ),
                                    if (job.status == 'COMPLETED')
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    JobPaymentsScreen(
                                                      api: widget.api,
                                                      job: job,
                                                    ),
                                              ),
                                            ),
                                        icon: const Icon(
                                          Icons.payments_outlined,
                                        ),
                                        label: const Text(
                                          'Thanh toán thu nhập',
                                        ),
                                      ),
                                    if (job.status == 'IN_PROGRESS')
                                      OutlinedButton.icon(
                                        onPressed: () => _complete(job),
                                        icon: const Icon(Icons.task_alt),
                                        label: const Text(
                                          'Hoàn thành công trình',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
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
  );
}

class _CreateJobDialog extends StatefulWidget {
  const _CreateJobDialog({required this.api, this.job});
  final ApiService api;
  final Job? job;
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
  late DateTimeRange _schedule = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  @override
  void initState() {
    super.initState();
    final j = widget.job;
    if (j != null) {
      _title.text = j.title;
      _description.text = j.description;
      _salary.text = j.salaryPerDay.toString();
      _address.text = j.address;
      _workers.text = '${j.requiredWorkers}';
      _type = j.jobType;
      _position = GeoPoint(j.latitude, j.longitude);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = j.startsOn == null || j.startsOn!.isBefore(today)
          ? today
          : j.startsOn!;
      final end = j.endsOn == null || j.endsOn!.isBefore(start)
          ? start
          : j.endsOn!;
      _schedule = DateTimeRange(start: start, end: end);
    }
  }

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
      final body = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'jobType': _type,
        'salaryPerDay': double.parse(_salary.text.trim()),
        'address': _address.text.trim(),
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'requiredWorkers': int.parse(_workers.text.trim()),
        'startsOn': isoDay(_schedule.start),
        'endsOn': isoDay(_schedule.end),
      };
      if (widget.job == null) {
        await widget.api.createJob(body);
      } else {
        await widget.api.updateJob(widget.job!.id, body);
      }
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
      title: Text(
        widget.job == null ? 'Đăng công trình mới' : 'Chỉnh sửa công trình',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
                JobLocationPin(
                  center: _position ?? const GeoPoint(10.7769, 106.7009),
                  selected: _position,
                  onPicked: _busy
                      ? null
                      : (point) => setState(() => _position = point),
                ),
                const SizedBox(height: 12),
                Text(
                  _position == null
                      ? 'Chưa chọn vị trí công trình'
                      : 'Vị trí: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final range = await showDateRangePicker(
                            context: context,
                            initialDateRange: _schedule,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (range != null && mounted) {
                            setState(() => _schedule = range);
                          }
                        },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    'Lịch: ${isoDay(_schedule.start)} – ${isoDay(_schedule.end)}',
                  ),
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
                const SizedBox(height: 16),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _salary,
                  builder: (context, _, child) =>
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _workers,
                        builder: (context, _, child) {
                          final parsedRate = double.tryParse(_salary.text);
                          final rate =
                              parsedRate != null &&
                                  parsedRate.isFinite &&
                                  parsedRate >= 0 &&
                                  parsedRate <= 1000000000
                              ? parsedRate
                              : 0.0;
                          final count = (int.tryParse(_workers.text) ?? 0)
                              .clamp(0, 10000);
                          final days =
                              _schedule.end.difference(_schedule.start).inDays +
                              1;
                          return FigmaCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Dự toán quỹ lương',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  money(rate * count * days),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '$count thợ × $days ngày. Đây là dự toán; đăng việc chưa tự khóa tiền. Thanh toán cần chấm công/nghiệm thu theo quy định.',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
        BouncingButton(
          child: FilledButton(
            onPressed: _busy || _gps ? null : _submit,
            child: Text(
              _busy
                  ? 'Đang lưu…'
                  : widget.job == null
                  ? 'Đăng việc'
                  : 'Lưu thay đổi',
            ),
          ),
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
  String _filter = '';
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
    if (application.crewBatchId != null) {
      final roster = _applications
          .where((a) => a.crewBatchId == application.crewBatchId)
          .toList();
      final agreed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            status == 'ACCEPTED'
                ? 'Nhận toàn bộ tổ đội?'
                : 'Từ chối toàn bộ tổ đội?',
          ),
          content: Text(
            '${roster.length} thợ: ${roster.map((a) => a.workerName).join(', ')}.\nThao tác áp dụng cho toàn nhóm; mỗi người có cam kết, chấm công và đánh giá riêng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại'),
            ),
            BouncingButton(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tiếp tục'),
              ),
            ),
          ],
        ),
      );
      if (agreed != true || !mounted) return;
    }
    setState(() {
      _updating = application.id;
      _error = null;
    });
    try {
      if (status == 'ACCEPTED' && application.job.startsOn != null) {
        final decision = await showHiringCommitment(
          context,
          widget.api,
          application,
        );
        if (decision == null || !mounted) return;
        if (application.crewBatchId != null) {
          await widget.api.crewDecision(
            application.crewBatchId!,
            status,
            version: decision.version,
            acceptOffer: decision.acceptOffer,
          );
        } else {
          await widget.api.acceptWithTerms(
            application.id,
            decision.version,
            acceptOffer: decision.acceptOffer,
          );
        }
      } else {
        if (application.crewBatchId != null) {
          await widget.api.crewDecision(application.crewBatchId!, status);
        } else {
          await widget.api.updateApplication(application.id, status);
        }
      }
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final status in ['', 'PENDING', 'ACCEPTED'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          status.isEmpty
                              ? 'Tất cả'
                              : '${status == 'PENDING' ? "Chờ duyệt" : "Đã duyệt"} (${_applications.where((a) => a.status == status).length})',
                        ),
                        selected: _filter == status,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_loading) const ContentSkeleton(compact: true),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
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
                for (final application in _applications.where(
                  (a) => _filter.isEmpty || a.status == _filter,
                ))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.workerName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (application.workerVerified) const KycBadge(),
                          const SizedBox(height: 8),
                          if (application.workerActive)
                            ApplicantEvidence(
                              key: ValueKey('evidence-${application.workerId}'),
                              api: widget.api,
                              workerId: application.workerId,
                            ),
                          if (application.proposedDailyRate != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Đề xuất ngày công: ${money(application.proposedDailyRate!.toDouble())}/ngày',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
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
                          if (application.crewBatchId != null &&
                              application.status == 'PENDING')
                            Text(
                              application.acceptedTermsAt != null &&
                                      application.consentVersion ==
                                          application.job.termsVersion
                                  ? 'Đã xác nhận cam kết'
                                  : 'Chờ thợ xác nhận cam kết',
                              style: TextStyle(
                                color:
                                    application.acceptedTermsAt != null &&
                                        application.consentVersion ==
                                            application.job.termsVersion
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          if (application.crewBatchId != null)
                            Text(
                              'Tổ đội #${application.crewBatchId} · duyệt/từ chối áp dụng cho toàn nhóm',
                            ),
                          if (!application.workerAvailable &&
                              application.status == 'PENDING')
                            const Text('Thợ đang tạm ngưng nhận việc'),
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
                          if (application.status == 'PENDING' ||
                              application.status == 'ACCEPTED')
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      application.status == 'ACCEPTED' &&
                                          application.workerActive
                                      ? ChatButton(
                                          api: widget.api,
                                          job: widget.job,
                                          peerId: application.workerId,
                                          peerName: application.workerName,
                                        )
                                      : Tooltip(
                                          message:
                                              'Nhắn tin sau khi đơn được duyệt',
                                          child: OutlinedButton.icon(
                                            onPressed: null,
                                            icon: Icon(
                                              Icons.chat_bubble_outline,
                                              size: 18,
                                            ),
                                            label: Text('Nhắn tin'),
                                          ),
                                        ),
                                ),
                                if (application.status == 'PENDING') ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: BouncingButton(
                                      child: FilledButton(
                                        onPressed:
                                            _updating != null ||
                                                _loading ||
                                                accepted >=
                                                    widget
                                                        .job
                                                        .requiredWorkers ||
                                                !application.workerActive ||
                                                !application.workerAvailable
                                            ? null
                                            : () => _decide(
                                                application,
                                                'ACCEPTED',
                                              ),
                                        child: Text(
                                          _updating == application.id
                                              ? 'Đang xử lý…'
                                              : application.crewBatchId != null
                                              ? 'Duyệt nhận cả tổ'
                                              : 'Duyệt nhận việc',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          if (application.status == 'PENDING')
                            TextButton(
                              onPressed: _updating != null || _loading
                                  ? null
                                  : () => _decide(application, 'REJECTED'),
                              child: Text(
                                application.crewBatchId != null
                                    ? 'Từ chối toàn tổ'
                                    : 'Từ chối',
                              ),
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
