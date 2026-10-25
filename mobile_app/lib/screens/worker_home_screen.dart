import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/coordinates_dialog.dart';
import '../widgets/job_card.dart';
import '../widgets/call_button.dart';
import '../widgets/chat_button.dart';
import 'profile_screen.dart';
import '../widgets/jobs_map.dart';

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
  int _tab = 0;
  int? _applying;
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
      final history = await widget.api.workerApplications();
      if (!mounted) return;
      setState(() => _applications = history);
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

  Future<void> _apply(Job job) async {
    setState(() => _applying = job.id);
    try {
      await widget.api.apply(job.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi ứng tuyển. Chờ chủ thầu duyệt.')),
      );
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _applying = null);
    }
  }

  Future<void> _showMapJob(Job job) async {
    final alreadyApplied = _applications.any((a) => a.job.id == job.id);
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: JobCard(
          job: job,
          action: FilledButton(
            onPressed: alreadyApplied || _applying != null
                ? null
                : () => Navigator.pop(context, true),
            child: Text(alreadyApplied ? 'Đã ứng tuyển' : 'Nhận việc'),
          ),
        ),
      ),
    );
    if (apply == true && mounted) await _apply(job);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thợ Xây'),
      actions: [
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
          onPressed: _loading ? null : () => _refresh(),
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
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Chào ${widget.api.session?.fullName ?? 'bạn'},',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _tab == 0 ? 'Tìm công trình gần bạn' : 'Việc đã ứng tuyển',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (_tab == 0) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.view_list_outlined),
                        label: Text('Danh sách'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.map_outlined),
                        label: Text('Bản đồ'),
                      ),
                    ],
                    selected: {_showMap},
                    onSelectionChanged: (value) =>
                        setState(() => _showMap = value.first),
                  ),
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
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Lấy lại GPS',
                        onPressed: _loading ? null : () => _refresh(gps: true),
                        icon: const Icon(Icons.my_location),
                      ),
                      IconButton(
                        tooltip: 'Chọn vị trí tìm việc',
                        onPressed: _loading ? null : _selectPosition,
                        icon: const Icon(Icons.edit_location_alt_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _jobType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Loại công việc',
                          ),
                          items: ['', 'Thợ chính', 'Phụ hồ']
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.isEmpty ? 'Tất cả' : type,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _loading
                              ? null
                              : (value) {
                                  setState(() => _jobType = value!);
                                  _refresh();
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _sort,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sắp xếp',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'DISTANCE',
                              child: Text(
                                'Gần nhất',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'SALARY_DESC',
                              child: Text(
                                'Lương cao nhất',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: _loading
                              ? null
                              : (value) {
                                  setState(() => _sort = value!);
                                  _refresh();
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (_error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!),
                    ),
                  ),
                if (_tab == 0) ...[
                  if (!_loading && _jobs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Chưa có công trình phù hợp. Thử tăng bán kính hoặc đổi vị trí.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_showMap && _position != null) ...[
                    SizedBox(
                      height: 360,
                      child: JobsMap(
                        center: _position!,
                        jobs: _jobs,
                        onJobTap: _showMapJob,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_jobs.length} công trình · Chạm ghim để xem và nhận việc',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_showMap && _position == null && !_loading)
                    TextButton.icon(
                      onPressed: _selectPosition,
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: const Text('Chọn vị trí tìm kiếm để xem bản đồ'),
                    ),
                  if (!_showMap)
                    for (final job in _jobs)
                      JobCard(
                        job: job,
                        action: FilledButton(
                          onPressed:
                              _applying != null ||
                                  _loading ||
                                  _applications.any((a) => a.job.id == job.id)
                              ? null
                              : () => _apply(job),
                          child: Text(
                            _applying == job.id
                                ? 'Đang gửi…'
                                : _applications.any((a) => a.job.id == job.id)
                                ? 'Đã ứng tuyển'
                                : 'Nhận việc',
                          ),
                        ),
                      ),
                ] else ...[
                  if (!_loading && _applications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Bạn chưa ứng tuyển công trình nào.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final application in _applications)
                    JobCard(
                      job: application.job,
                      canContactContractor: application.status == 'ACCEPTED',
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
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.near_me_outlined),
          label: 'Gần bạn',
        ),
        NavigationDestination(
          icon: Icon(Icons.work_history_outlined),
          label: 'Đã ứng tuyển',
        ),
      ],
    ),
  );
}
