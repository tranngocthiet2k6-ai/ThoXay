import '../widgets/design_motion.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../models/attendance.dart';
import '../models/scheduling.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/device_photo_picker.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/private_image.dart';
import '../widgets/photo_preview_dialog.dart';
import '../widgets/shift_code_dialog.dart';
import 'shift_scanner_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.api,
    required this.job,
    this.applicationId,
    this.location,
    this.picker,
  });
  final ApiService api;
  final Job job;
  final int? applicationId;
  final LocationService? location;
  final DevicePhotoPicker? picker;
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  AttendancePage? _data;
  List<AttendanceEntry> _items = [];
  bool _loading = true, _busy = false, _choosing = false;
  String? _error;
  DateTime _day = DateTime.now().toUtc().add(const Duration(hours: 7));
  int _page = 0, _generation = 0;
  bool get _worker => widget.applicationId != null;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = _worker
          ? await widget.api.attendance(
              widget.applicationId!,
              beforeDay: more && _items.isNotEmpty ? _items.last.day : null,
            )
          : await widget.api.jobAttendance(
              widget.job.id,
              _day,
              page: more ? _page + 1 : 0,
            );
      if (mounted && generation == _generation) {
        setState(() {
          _data = data;
          _items = more ? [..._items, ...data.items] : data.items;
          _page = more ? _page + 1 : 0;
        });
      }
    } on ApiException catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _mark(bool checkout, {String? qr}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final point = qr == null
          ? await (widget.location ?? LocationService()).currentPosition()
          : null;
      final data = await widget.api.markAttendance(
        widget.applicationId!,
        checkout,
        position: point,
        qrToken: qr,
      );
      if (mounted) {
        setState(() {
          _data = data;
          _items = data.items;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _qr(bool checkout) async {
    if (_busy || _choosing) return;
    _choosing = true;
    try {
      final token = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => ShiftScannerScreen(jobId: widget.job.id),
        ),
      );
      if (token != null && mounted) await _mark(checkout, qr: token);
    } finally {
      _choosing = false;
    }
  }

  Future<void> _manual(bool checkout) async {
    final token = await showDialog<String>(
      context: context,
      builder: (_) => const _CodeInput(),
    );
    if (token != null && mounted) await _mark(checkout, qr: token);
  }

  Future<void> _upload(AttendanceEntry row, ImageSource source) async {
    if (_busy || _choosing) return;
    _choosing = true;
    try {
      final bytes = await (widget.picker ?? DevicePhotoPicker()).pick(source);
      if (bytes == null || !mounted) return;
      final caption = await showDialog<String>(
        context: context,
        builder: (_) => PhotoPreviewDialog(
          bytes: bytes,
          title: 'Ảnh công việc cuối ngày',
          maxCaption: 1000,
        ),
      );
      if (caption == null || !mounted) return;
      setState(() => _busy = true);
      final data = await widget.api.uploadWorkLog(
        widget.applicationId!,
        row.day,
        bytes,
        caption,
      );
      if (mounted) {
        setState(() {
          _data = data;
          _items = data.items;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Không mở được camera/thư viện. Hãy kiểm tra quyền truy cập.',
        );
      }
    } finally {
      _choosing = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(AttendanceEntry row, bool approved) async {
    final feedback = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewDialog(approved: approved),
    );
    if (feedback == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.reviewWorkLog(
        row.logId!,
        row.logVersion!,
        approved,
        feedback,
      );
      if (mounted) {
        setState(() => _busy = false);
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _time(DateTime? t) {
    if (t == null) return 'Chưa ghi nhận';
    final vn = t.toUtc().add(const Duration(hours: 7));
    return '${vn.hour.toString().padLeft(2, '0')}:${vn.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    AttendanceEntry? today;
    for (final row in _items) {
      if (_data != null && isoDay(row.day) == isoDay(_data!.today)) today = row;
    }
    final checkout = today != null && today.checkedOutAt == null;
    final done = today?.checkedOutAt != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(_worker ? 'Chấm công của tôi' : 'Chấm công & nghiệm thu'),
        actions: [
          IconButton(
            onPressed: _loading || _busy ? null : () => _load(),
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ContentFrame(
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.job.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _worker
                            ? 'Chấm công tại công trường trong 200m, hoặc dùng mã ca làm chủ thầu cấp. Ảnh cuối ngày cần được nghiệm thu trước thanh toán.'
                            : 'Đối chiếu giờ vào/ra và ảnh thực tế trước khi nghiệm thu. Mã QR có hiệu lực 5 phút.',
                      ),
                      if (widget.job.attendanceRequired)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Công trình này yêu cầu chấm công và ảnh nghiệm thu khi thanh toán.',
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_worker && _data != null) ...[
                        Text('Ngày Việt Nam: ${isoDay(_data!.today)}'),
                        const SizedBox(height: 12),
                        if (done)
                          const Text(
                            'Đã check-out hôm nay. Gửi ảnh kết quả công việc bên dưới.',
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: _busy || _loading
                                    ? null
                                    : () => _mark(checkout),
                                icon: const Icon(Icons.my_location),
                                label: Text(
                                  checkout ? 'Check-out GPS' : 'Check-in GPS',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _busy || _loading
                                    ? null
                                    : () => _qr(checkout),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Quét QR ca làm'),
                              ),
                              TextButton(
                                onPressed: _busy || _loading
                                    ? null
                                    : () => _manual(checkout),
                                child: const Text('Nhập mã ca làm'),
                              ),
                            ],
                          ),
                      ],
                      if (!_worker)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      final day = await showDatePicker(
                                        context: context,
                                        initialDate: _day,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 1),
                                        ),
                                      );
                                      if (day != null && mounted) {
                                        setState(() => _day = day);
                                        await _load();
                                      }
                                    },
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(isoDay(_day)),
                            ),
                            FilledButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => showDialog<void>(
                                      context: context,
                                      builder: (_) => ShiftCodeDialog(
                                        api: widget.api,
                                        jobId: widget.job.id,
                                      ),
                                    ),
                              icon: const Icon(Icons.qr_code_2),
                              label: const Text('Tạo QR ca làm'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading && _items.isEmpty) const ContentSkeleton(),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                ),
              if (!_loading && _error == null && _items.isEmpty)
                EmptyState(
                  title: 'Chưa có ngày công',
                  message: _worker
                      ? 'Check-in khi đến công trường để bắt đầu ghi nhận ngày công.'
                      : 'Chọn ngày cần xem hoặc cấp QR cho thợ chấm công.',
                  action: TextButton(
                    onPressed: () => _load(),
                    child: const Text('Làm mới danh sách'),
                  ),
                ),
              for (final row in _items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${row.workerName} · ${isoDay(row.day)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vào: ${_time(row.checkedInAt)} · Ra: ${_time(row.checkedOutAt)}',
                        ),
                        const SizedBox(height: 12),
                        if (row.photoPath != null) ...[
                          InkWell(
                            onTap: () => showPrivatePhoto(
                              context,
                              widget.api,
                              row.photoPath!,
                              row.caption,
                            ),
                            child: SizedBox(
                              height: 220,
                              child: PrivateImage(
                                api: widget.api,
                                path: row.photoPath!,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(row.caption),
                          Chip(
                            label: Text(
                              row.reviewStatus == 'APPROVED'
                                  ? 'Đã nghiệm thu'
                                  : row.reviewStatus == 'CHANGES_REQUESTED'
                                  ? 'Cần bổ sung ảnh'
                                  : 'Chờ nghiệm thu',
                            ),
                          ),
                          if (row.feedback.isNotEmpty)
                            Text('Phản hồi: ${row.feedback}'),
                        ],
                        if (_worker &&
                            row.checkedOutAt != null &&
                            row.reviewStatus != 'APPROVED')
                          PopupMenuButton<ImageSource>(
                            enabled: !_busy && !_loading,
                            onSelected: (source) => _upload(row, source),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: ImageSource.camera,
                                child: Text('Chụp kết quả công việc'),
                              ),
                              PopupMenuItem(
                                value: ImageSource.gallery,
                                child: Text('Chọn ảnh kết quả'),
                              ),
                            ],
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined),
                                  SizedBox(width: 8),
                                  Text('Gửi ảnh cuối ngày'),
                                ],
                              ),
                            ),
                          ),
                        if (!_worker &&
                            row.logId != null &&
                            row.logVersion != null &&
                            row.reviewStatus != 'APPROVED')
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _review(row, true),
                                icon: const Icon(Icons.task_alt),
                                label: const Text('Nghiệm thu ngày công'),
                              ),
                              OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => _review(row, false),
                                child: const Text('Yêu cầu bổ sung'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              if (_data?.hasMore == true)
                TextButton(
                  onPressed: _loading || _busy ? null : () => _load(more: true),
                  child: const Text('Tải thêm ngày công'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeInput extends StatefulWidget {
  const _CodeInput();
  @override
  State<_CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<_CodeInput> {
  final _text = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nhập mã ca làm'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _text,
        maxLength: 43,
        decoration: const InputDecoration(labelText: 'Mã chủ thầu cung cấp'),
        validator: (v) =>
            RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(v?.trim() ?? '')
            ? null
            : 'Mã ca làm gồm 43 ký tự',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _text.text.trim());
          }
        },
        child: const Text('Xác nhận chấm công'),
      ),
    ],
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.approved});
  final bool approved;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _feedback = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.approved ? 'Xác nhận nghiệm thu?' : 'Yêu cầu bổ sung ảnh',
    ),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.approved
                ? 'Bạn xác nhận đã xem ảnh và đối chiếu kết quả công việc của ngày này. Ngày đã nghiệm thu không thể thay ảnh.'
                : 'Nêu rõ phần cần bổ sung để người thợ gửi lại ảnh.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _feedback,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Phản hồi'),
            validator: (v) => !widget.approved && (v?.trim().isEmpty ?? true)
                ? 'Nhập nội dung cần bổ sung'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _feedback.text.trim());
          }
        },
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
