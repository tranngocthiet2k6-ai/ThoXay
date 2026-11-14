import 'main_shell.dart';
import '../widgets/bouncing_button.dart';
import '../services/device_preferences.dart';
import '../widgets/modern_controls.dart';
import '../widgets/job_application_actions.dart';
import '../widgets/wage_offer_sheet.dart';
import 'chat_screen.dart';
import '../widgets/figma_job_map.dart';
import '../widgets/week_schedule.dart';
import 'calendar_screen.dart';
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
import '../widgets/jobs_map.dart';
import '../widgets/loading_jobs.dart';
import '../widgets/empty_state.dart';
import '../widgets/hero_greeting.dart';
import '../widgets/job_search_header.dart';
import '../widgets/cancel_work_dialog.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key, required this.api, this.location});
  final ApiService api;
  final LocationService? location;
  @override
  Widget build(BuildContext context) =>
      MainShell(api: api, worker: true, location: location);
}

class WorkerHomeContent extends StatefulWidget {
  const WorkerHomeContent({
    super.key,
    required this.api,
    this.location,
    required this.tab,
    required this.onTabChanged,
  });
  final ApiService api;
  final LocationService? location;
  final int tab;
  final ValueChanged<int> onTabChanged;
  @override
  State<WorkerHomeContent> createState() => _WorkerHomeContentState();
}

class _WorkerHomeContentState extends State<WorkerHomeContent> {
  List<Job> _jobs = [];
  List<JobApplication> _applications = [];
  GeoPoint? _position;
  double _radius = DevicePreferences.instance.radius;
  String _jobType = '', _sort = 'DISTANCE';
  final _search = TextEditingController();
  String _query = '';
  List<Job> get _visibleJobs => _jobs
      .where(
        (j) => '${j.title} ${j.address} ${j.jobType}'.toLowerCase().contains(
          _query.toLowerCase().trim(),
        ),
      )
      .toList();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int get _tab => widget.tab;
  int _workStatus = 0;
  List<JobApplication> get _filteredApplications => _applications
      .where(
        (a) => switch (_workStatus) {
          0 => a.status == 'ACCEPTED' && a.job.status != 'COMPLETED',
          1 => a.status == 'PENDING',
          2 => a.job.status == 'COMPLETED',
          _ => true,
        },
      )
      .toList();
  int? _applying;
  bool _cancelling = false;
  bool? _available;
  bool _availabilityBusy = false;
  bool _loading = false;
  bool _showMap = false, _advancedFilters = false;
  bool _proposalOpen = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh({bool gps = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final available = await widget.api.availability();
      if (!mounted) return;
      setState(() {
        _available = available;
        if (!available) _jobs = [];
      });
      final history = await widget.api.workerApplications();
      if (!mounted) return;
      setState(() => _applications = history);
      if (!available) return;
      if (_position == null || gps) {
        _position = await (widget.location ?? LocationService())
            .currentPosition();
      }
      final jobs = await widget.api.nearby(
        _position!.latitude,
        _position!.longitude,
        _radius,
        jobType: _jobType.isEmpty ? null : _jobType,
        sort: _sort,
      );
      if (mounted) setState(() => _jobs = jobs);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPosition() async {
    final point = await showCoordinatesDialog(context, current: _position);
    if (point == null || !mounted) return;
    setState(() => _position = point);
    await _refresh();
  }

  Future<void> _setAvailable(bool value) async {
    if (_availabilityBusy || _loading || _cancelling) return;
    setState(() => _availabilityBusy = true);
    try {
      final saved = await widget.api.setAvailability(value);
      if (!mounted) return;
      setState(() {
        _available = saved;
        if (!saved) _jobs = [];
      });
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _availabilityBusy = false);
    }
  }

  Future<void> _apply(Job job, {bool negotiate = false}) async {
    if (_proposalOpen ||
        _applying != null ||
        _applications.any((a) => a.job.id == job.id)) {
      return;
    }
    WorkProposal? proposal;
    if (job.startsOn != null) {
      setState(() => _proposalOpen = true);
      try {
        WageOffer? offer;
        if (negotiate) {
          offer = await showWageOffer(context);
          if (offer == null || !mounted) return;
        }
        if (!mounted) return;
        proposal = await showWorkProposal(
          context,
          widget.api,
          job,
          proposedRate: offer?.rate,
          note: offer?.note ?? '',
        );
      } finally {
        if (mounted) setState(() => _proposalOpen = false);
      }
      if (proposal == null || !mounted) return;
    }
    setState(() => _applying = job.id);
    try {
      if (proposal != null) {
        await widget.api.applyWithTerms(job.id, proposal);
      } else {
        await widget.api.apply(job.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: const Text('Đã gửi ứng tuyển. Chờ chủ thầu duyệt.'),
        ),
      );
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = null);
    }
  }

  Future<void> _showMapJob(Job job) async {
    if (_cancelling) return;
    final alreadyApplied = _applications.any((a) => a.job.id == job.id);
    final canChat = _applications.any(
      (a) => a.job.id == job.id && a.status == 'ACCEPTED',
    );
    await showJobDetails<void>(
      context,
      job,
      api: widget.api,
      actionBuilder: (sheetContext) => JobApplicationActions(
        applied: alreadyApplied,
        busy: _applying != null || _proposalOpen || _loading,
        onApply: () {
          Navigator.pop(sheetContext);
          _apply(job);
        },
        onNegotiate: job.startsOn == null
            ? null
            : () {
                Navigator.pop(sheetContext);
                _apply(job, negotiate: true);
              },
        onChat: !canChat
            ? null
            : () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatScreen(
                      api: widget.api,
                      job: job,
                      peerId: job.contractorId,
                      peerName: job.contractorName,
                    ),
                  ),
                );
              },
      ),
    );
  }

  Future<void> _cancel(JobApplication application) async {
    if (_cancelling || _loading) return;
    setState(() => _cancelling = true);
    try {
      final reason = await showCancelWorkDialog(context);
      if (reason == null || !mounted) return;
      final result = await widget.api.cancelApplication(application.id, reason);
      if (!mounted) return;
      setState(() => _workStatus = 3);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: Text(
            'Đã hủy việc. Trừ ${result.cancellationPenalty} điểm uy tín.',
          ),
        ),
      );
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _withdrawCrew(JobApplication application) async {
    if (_cancelling || _loading) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rút đơn tổ đội?'),
        content: const Text(
          'Rút đơn đang chờ sẽ rút toàn bộ tổ khỏi công trình. Không trừ điểm uy tín khi tổ chưa được duyệt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          BouncingButton(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rút toàn bộ tổ'),
            ),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await widget.api.withdrawCrew(application.crewBatchId!);
      if (mounted) await _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _confirmTerms(JobApplication application) async {
    final proposal = await showWorkerCommitment(
      context,
      widget.api,
      application,
    );
    if (proposal == null || !mounted) return;
    try {
      await widget.api.confirmCommitment(application.id, proposal.version);
      if (mounted) await _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (!_cancelling) await _refresh();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        HeroGreeting(
                          api: widget.api,
                          availability: _available,
                          onAvailabilityChanged:
                              _loading ||
                                  _cancelling ||
                                  _availabilityBusy ||
                                  _available == null
                              ? null
                              : _setAvailable,
                          title: _tab == 0
                              ? 'Tìm công trình gần bạn'
                              : 'Việc đã ứng tuyển',
                          subtitle: _tab == 0
                              ? 'Việc gần nhà. Thợ đúng nghề.'
                              : 'Theo dõi đơn và kết nối với chủ thầu của bạn.',
                        ),
                        if (_availabilityBusy) const LinearProgressIndicator(),
                        if (_tab == 1) ...[
                          const SizedBox(height: 16),
                          WeekSchedule(
                            jobs: _applications
                                .where((a) => a.status == 'ACCEPTED')
                                .map((a) => a.job)
                                .toList(),
                            onOpenCalendar: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CalendarScreen(api: widget.api),
                              ),
                            ),
                          ),
                        ],
                        if (_tab == 0 &&
                            _position != null &&
                            _advancedFilters) ...[
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text(
                              'Thời tiết khu vực',
                              style: TextStyle(fontSize: 12),
                            ),
                            children: [
                              WeatherCard(
                                api: widget.api,
                                latitude: _position!.latitude,
                                longitude: _position!.longitude,
                                areaLabel: 'Khu vực đang tìm việc',
                                refreshToken: _jobs,
                              ),
                            ],
                          ),
                        ],
                        if (_tab == 0 &&
                            _available == true &&
                            _advancedFilters) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<double>(
                                  initialValue: _radius,
                                  decoration: const InputDecoration(
                                    labelText: 'Bán kính tìm việc',
                                  ),
                                  items:
                                      [2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0]
                                          .map(
                                            (r) => DropdownMenuItem(
                                              value: r,
                                              child: Text('${r.toInt()} km'),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: _loading
                                      ? null
                                      : (r) {
                                          setState(() => _radius = r!);
                                          _refresh();
                                        },
                                ),
                              ),
                              IconButton(
                                tooltip: 'Lấy lại GPS',
                                onPressed: _loading
                                    ? null
                                    : () => _refresh(gps: true),
                                icon: const Icon(Icons.my_location),
                              ),
                              IconButton(
                                tooltip: 'Chọn vị trí tìm việc',
                                onPressed: _loading ? null : _selectPosition,
                                icon: const Icon(
                                  Icons.edit_location_alt_outlined,
                                ),
                              ),
                              IconButton(
                                tooltip: _showMap
                                    ? 'Xem danh sách'
                                    : 'Xem bản đồ',
                                onPressed: () =>
                                    setState(() => _showMap = !_showMap),
                                icon: Icon(
                                  _showMap
                                      ? Icons.view_list_outlined
                                      : Icons.map_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_tab == 0 && _available == true)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: JobSearchHeader(
                      height:
                          (_showMap ? 176 : 128) *
                          MediaQuery.textScalerOf(context).scale(14) /
                          14,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: JobSearchFilters(
                                controller: _search,
                                onAdvanced: () => setState(
                                  () => _advancedFilters = !_advancedFilters,
                                ),
                                jobType: _jobType,
                                salaryFirst: _sort == 'SALARY_DESC',
                                enabled: !_loading,
                                onSearch: (q) => setState(() => _query = q),
                                onType: (type) {
                                  setState(() => _jobType = type);
                                  _refresh();
                                },
                                onSalary: (v) {
                                  setState(
                                    () =>
                                        _sort = v ? 'SALARY_DESC' : 'DISTANCE',
                                  );
                                  _refresh();
                                },
                              ),
                            ),
                            if (_showMap)
                              SizedBox(
                                height: 48,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Đang xem bản đồ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                    TextButton.icon(
                                      key: const ValueKey('exit-job-map'),
                                      onPressed: () {
                                        AppHaptics.light();
                                        setState(() => _showMap = false);
                                      },
                                      icon: const Icon(
                                        Icons.view_list_outlined,
                                        size: 20,
                                      ),
                                      label: const Text('Về danh sách'),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                      if (_loading)
                        LoadingJobs(mapMode: _tab == 0 && _showMap)
                      else if (_tab == 0) ...[
                        if (!_showMap &&
                            _position != null &&
                            _available == true &&
                            _visibleJobs.isNotEmpty) ...[
                          JobMapPreview(
                            center: _position!,
                            jobs: _visibleJobs,
                            onJobTap: _showMapJob,
                            onExpand: () => setState(() => _showMap = true),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Việc gần anh',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_available == false)
                          const EmptyState(
                            title: 'Bạn đang tạm ngưng nhận việc',
                            message: 'Bật trạng thái nhận việc khi sẵn sàng. Bạn vẫn xem được lịch sử và trao đổi trong công trình đã nhận.',
                          ),
                        if (_available == true &&
                            _visibleJobs.isEmpty &&
                            _error == null)
                          EmptyState(
                            title: 'Không tìm thấy công trình quanh đây',
                            message: 'Thử tăng bán kính, đổi loại việc hoặc chọn một vị trí khác. Cơ hội phù hợp có thể ở gần bạn hơn đấy!',
                            action: OutlinedButton.icon(
                              onPressed: _selectPosition,
                              icon: const Icon(
                                Icons.edit_location_alt_outlined,
                              ),
                              label: const Text('Đổi vị trí tìm kiếm'),
                            ),
                          ),
                        if (_visibleJobs.isEmpty) const SizedBox(height: 16),
                        if (_showMap &&
                            _position != null &&
                            _available == true) ...[
                          SizedBox(
                            height: 360,
                            child: JobsMap(
                              center: _position!,
                              jobs: _visibleJobs,
                              onJobTap: _showMapJob,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_visibleJobs.length} công trình · Chạm ghim để xem và nhận việc',
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_showMap &&
                            _position == null &&
                            !_loading &&
                            _available == true)
                          TextButton.icon(
                            onPressed: _selectPosition,
                            icon: const Icon(Icons.edit_location_alt_outlined),
                            label: const Text(
                              'Chọn vị trí tìm kiếm để xem bản đồ',
                            ),
                          ),
                        if (!_showMap)
                          ResponsiveJobGrid(
                            children: [
                              for (final job in _visibleJobs)
                                JobCard(
                                  api: widget.api,
                                  job: job,
                                  previewOnly: true,
                                  onTap: () => _showMapJob(job),
                                  action: const SizedBox.shrink(),
                                ),
                            ],
                          ),
                      ] else ...[
                        PillTabs(
                          labels: const [
                            'Đang làm',
                            'Chờ duyệt',
                            'Hoàn thành',
                            'Tất cả',
                          ],
                          selected: _workStatus,
                          onChanged: (index) =>
                              setState(() => _workStatus = index),
                        ),
                        const SizedBox(height: 16),
                        if (_applications.isNotEmpty &&
                            _filteredApplications.isEmpty)
                          EmptyState(
                            title: 'Chưa có việc ở trạng thái này',
                            message: 'Các đơn và công trình của bạn sẽ được cập nhật tại đây.',
                            action: TextButton(
                              onPressed: () => setState(() => _workStatus = 3),
                              child: const Text('Xem tất cả việc'),
                            ),
                          ),
                        if (_applications.isEmpty && _error == null)
                          EmptyState(
                            title: 'Hành trình mới bắt đầu',
                            message: 'Bạn chưa ứng tuyển công trình nào. Khám phá công việc gần bạn và gửi đơn đầu tiên nhé!',
                            action: BouncingButton(
                              child: FilledButton(
                                onPressed: () => widget.onTabChanged(0),
                                child: const Text('Khám phá công trình'),
                              ),
                            ),
                          ),
                        for (final application in _filteredApplications)
                          JobCard(
                            api: widget.api,
                            job: application.job,
                            canContactContractor:
                                application.status == 'ACCEPTED',
                            action: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Chip(
                                  label: Text(statusLabel(application.status)),
                                  avatar: Icon(
                                    application.status == 'ACCEPTED'
                                        ? Icons.check_circle_outline
                                        : application.status == 'REJECTED'
                                        ? Icons.cancel_outlined
                                        : Icons.schedule,
                                    size: 18,
                                  ),
                                ),
                                if (application.crewBatchId != null)
                                  Chip(
                                    avatar: const Icon(
                                      Icons.groups_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Tổ đội #${application.crewBatchId}',
                                    ),
                                  ),
                                if (application.crewBatchId != null &&
                                    application.status == 'PENDING')
                                  TextButton.icon(
                                    onPressed: _cancelling || _loading
                                        ? null
                                        : () => _withdrawCrew(application),
                                    icon: const Icon(
                                      Icons.group_remove_outlined,
                                    ),
                                    label: const Text(
                                      'Không tham gia công trình tổ đội',
                                    ),
                                  ),
                                if (application.status == 'ACCEPTED')
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => AttendanceScreen(
                                          api: widget.api,
                                          job: application.job,
                                          applicationId: application.id,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.fact_check_outlined),
                                    label: const Text(
                                      'Chấm công & ảnh cuối ngày',
                                    ),
                                  ),
                                if ([
                                  'ACCEPTED',
                                  'CANCELLED',
                                ].contains(application.status))
                                  IncidentActions(
                                    api: widget.api,
                                    job: application.job,
                                    compact: true,
                                  ),
                                if (application.jobRating != null)
                                  Text(
                                    'Đánh giá công trình: ${application.jobRating}/5 ★',
                                  ),
                                if (application.status == 'CANCELLED')
                                  Text(
                                    'Lý do: ${application.cancellationReason ?? "Đã hủy việc"}\nĐã trừ ${application.cancellationPenalty} điểm uy tín.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                if (application.status == 'ACCEPTED' &&
                                    application.job.status == 'IN_PROGRESS')
                                  OutlinedButton.icon(
                                    onPressed: _loading || _cancelling
                                        ? null
                                        : () => _cancel(application),
                                    icon: const Icon(Icons.work_off_outlined),
                                    label: Text(
                                      _cancelling
                                          ? 'Đang xử lý…'
                                          : 'Hủy việc đang làm',
                                    ),
                                  ),
                                if (application.status == 'ACCEPTED')
                                  ChatButton(
                                    api: widget.api,
                                    job: application.job,
                                    peerId: application.job.contractorId,
                                    peerName: application.job.contractorName,
                                  ),
                                if (application.status == 'PENDING' &&
                                    application.job.startsOn != null)
                                  TextButton.icon(
                                    onPressed: () => _confirmTerms(application),
                                    icon: const Icon(
                                      Icons.description_outlined,
                                    ),
                                    label: const Text('Xem & xác nhận cam kết'),
                                  ),
                                if (application.agreedDailyRate != null)
                                  Text(
                                    'Lương chốt: ${money(application.agreedDailyRate!.toDouble())}/ngày',
                                  ),
                                if (application.status == 'ACCEPTED' &&
                                    application.job.contractorPhone != null)
                                  CallButton(
                                    phone: application.job.contractorPhone!,
                                    label: 'Gọi chủ thầu',
                                  ),
                              ],
                            ),
                          ),
                      ],
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
