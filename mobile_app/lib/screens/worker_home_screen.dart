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
import '../widgets/finance_menu.dart';
import '../widgets/home_navigation.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key, required this.api, this.location});
  final ApiService api;
  final LocationService? location;
  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  List<Job> _jobs = [];
  List<JobApplication> _applications = [];
  GeoPoint? _position;
  double _radius = 10;
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

  int _tab = 0;
  int? _applying;
  bool _cancelling = false;
  bool? _available;
  bool _availabilityBusy = false;
  bool _loading = false;
  bool _showMap = false;
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

  Future<void> _apply(Job job) async {
    if (_applying != null || _applications.any((a) => a.job.id == job.id)) {
      return;
    }
    setState(() => _applying = job.id);
    try {
      await widget.api.apply(job.id);
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
    final apply = await showJobDetails<bool>(
      context,
      job,
      action: FilledButton(
        onPressed: alreadyApplied || _applying != null
            ? null
            : () => Navigator.pop(context, true),
        child: Text(alreadyApplied ? 'Đã ứng tuyển' : 'Nhận việc'),
      ),
    );
    if (apply == true && mounted) await _apply(job);
  }

  Future<void> _cancel(JobApplication application) async {
    if (_cancelling || _loading) return;
    setState(() => _cancelling = true);
    try {
      final reason = await showCancelWorkDialog(context);
      if (reason == null || !mounted) return;
      final result = await widget.api.cancelApplication(application.id, reason);
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thợ Xây'),
      actions: [
        FinanceMenu(api: widget.api, worker: true),
        IconButton(
          tooltip: 'Làm mới',
          onPressed: _loading || _cancelling ? null : () => _refresh(),
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
            onRefresh: () async {
              if (!_cancelling) await _refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        if (_tab == 0 && _available == true) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<double>(
                                  initialValue: _radius,
                                  decoration: const InputDecoration(
                                    labelText: 'Bán kính tìm việc',
                                  ),
                                  items: [5.0, 10.0, 20.0, 50.0, 100.0, 200.0]
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
                          144 * MediaQuery.textScalerOf(context).scale(14) / 14,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: JobSearchFilters(
                          controller: _search,
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
                              () => _sort = v ? 'SALARY_DESC' : 'DISTANCE',
                            );
                            _refresh();
                          },
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
                          for (final job in _visibleJobs)
                            JobCard(
                              job: job,
                              action: FilledButton(
                                onPressed:
                                    _applying != null ||
                                        _cancelling ||
                                        _loading ||
                                        _applications.any(
                                          (a) => a.job.id == job.id,
                                        )
                                    ? null
                                    : () => _apply(job),
                                child: Text(
                                  _applying == job.id
                                      ? 'Đang gửi…'
                                      : _applications.any(
                                          (a) => a.job.id == job.id,
                                        )
                                      ? 'Đã ứng tuyển'
                                      : 'Nhận việc',
                                ),
                              ),
                            ),
                      ] else ...[
                        if (_applications.isEmpty && _error == null)
                          EmptyState(
                            title: 'Hành trình mới bắt đầu',
                            message: 'Bạn chưa ứng tuyển công trình nào. Khám phá công việc gần bạn và gửi đơn đầu tiên nhé!',
                            action: FilledButton(
                              onPressed: () => setState(() => _tab = 0),
                              child: const Text('Khám phá công trình'),
                            ),
                          ),
                        for (final application in _applications)
                          JobCard(
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
    bottomNavigationBar: HomeNavigation(
      api: widget.api,
      worker: true,
      selectedIndex: _tab,
      onSelected: (index) => setState(() => _tab = index),
    ),
  );
}
