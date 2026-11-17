import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/models.dart';
import '../models/qr_action.dart';
import '../services/api_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/design_motion.dart';
import '../widgets/empty_state.dart';
import '../widgets/qr_camera.dart';
import '../widgets/shift_code_dialog.dart';
import '../widgets/vietqr_review.dart';
import 'attendance_screen.dart';
import 'shared_job_screen.dart';

class QrHubScreen extends StatefulWidget {
  const QrHubScreen({
    super.key,
    required this.api,
    required this.worker,
    required this.active,
    this.scannerBuilder,
    this.onWorkerSaved,
  });
  final ApiService api;
  final bool worker, active;
  final Widget Function(ValueChanged<String>)? scannerBuilder;
  final VoidCallback? onWorkerSaved;
  @override
  State<QrHubScreen> createState() => _QrHubScreenState();
}

class _QrHubScreenState extends State<QrHubScreen> {
  int _mode = 0;
  bool _camera = false, _busy = false, _loading = false;
  String? _error;
  List<Job> _jobs = [];
  int? _jobId;
  @override
  void didUpdateWidget(covariant QrHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && _camera) _camera = false;
  }

  Future<void> _loadJobs() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobs = await widget.api.contractorJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs
              .where((j) => ['OPEN', 'IN_PROGRESS'].contains(j.status))
              .toList();
          _jobId = _jobs.firstOrNull?.id;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _modeChanged(int mode) {
    setState(() {
      _mode = mode;
      _camera = false;
      _error = null;
    });
    if (mode == 1 && !widget.worker) _loadJobs();
  }

  Future<bool> _confirm(String title, String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _scan(String raw) async {
    if (_busy || !widget.active) return;
    setState(() {
      _busy = true;
      _camera = false;
      _error = null;
    });
    try {
      final action = QrAction.parse(raw);
      if (action == null) {
        throw const ApiException(
          'Mã QR không hợp lệ hoặc chưa được hỗ trợ. Hãy dùng mã điểm danh Thợ Xây, mã thợ, liên kết công trình hoặc VietQR chuyển khoản.',
        );
      }
      switch (action.kind) {
        case QrKind.attendance:
          await _attendance(action);
        case QrKind.worker:
          await _saveWorker(action.id!);
        case QrKind.job:
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    SharedJobScreen(api: widget.api, jobId: action.id!),
              ),
            );
          }
        case QrKind.payment:
          if (mounted) {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => VietQrReview(payment: action.payment!),
            );
          }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attendance(QrAction action) async {
    if (!widget.worker) {
      final jobs = await widget.api.contractorJobs();
      final job = jobs.where((j) => j.id == action.id).firstOrNull;
      if (job == null) {
        throw const ApiException(
          'Bạn chỉ xem điểm danh công trình do mình quản lý.',
        );
      }
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => AttendanceScreen(api: widget.api, job: job),
          ),
        );
      }
      return;
    }
    final applications = await widget.api.workerApplications();
    final application = applications
        .where((a) => a.job.id == action.id && a.status == 'ACCEPTED')
        .firstOrNull;
    if (application == null) {
      throw const ApiException(
        'Bạn cần được duyệt nhận công trình này trước khi chấm công.',
      );
    }
    final page = await widget.api.attendance(application.id);
    final today = page.items
        .where(
          (row) =>
              row.day.year == page.today.year &&
              row.day.month == page.today.month &&
              row.day.day == page.today.day,
        )
        .firstOrNull;
    if (today?.checkedOutAt != null) {
      throw const ApiException(
        'Bạn đã kết thúc ca hôm nay. Không ghi nhận thêm ca trùng.',
      );
    }
    if (!mounted || !widget.active) return;
    final checkout = today != null;
    final yes = await _confirm(
      checkout ? 'Xác nhận kết thúc ca' : 'Xác nhận vào ca',
      '${application.job.title}\n${checkout ? "Ghi giờ ra" : "Ghi giờ vào"} bằng mã QR chủ thầu cấp. Backend kiểm tra hiệu lực mã và ghi giờ chính thức.',
      checkout ? 'Kết thúc ca' : 'Vào ca',
    );
    if (!yes || !mounted) return;
    await widget.api.markAttendance(
      application.id,
      checkout,
      qrToken: action.token,
    );
    if (!mounted || !widget.active) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar(
        content: Text(
          checkout
              ? 'Đã kết thúc ca. Gửi hai ảnh để chủ thầu nghiệm thu.'
              : 'Đã ghi nhận vào ca.',
        ),
      ),
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AttendanceScreen(
          api: widget.api,
          job: application.job,
          applicationId: application.id,
        ),
      ),
    );
  }

  Future<void> _saveWorker(int id) async {
    if (widget.worker) {
      throw const ApiException(
        'Mã thợ dành cho Chủ thầu lưu vào Đội thợ. Thợ dùng QR công trình để chấm công.',
      );
    }
    final worker = await widget.api.workerProfile(id);
    if (!mounted || !widget.active) return;
    final yes = await _confirm(
      'Lưu thợ vào đội ngũ?',
      '${worker.fullName}\n${worker.verified ? "Đã xác thực CCCD" : "Chưa xác thực CCCD"} · ${worker.rating.toStringAsFixed(1)} ★\nMã QR chỉ chứa mã hồ sơ. Việc lưu thợ không tự tạo hợp đồng hay cấp quyền liên lạc.',
      'Lưu vào Đội thợ',
    );
    if (!yes || !mounted) return;
    await widget.api.saveWorker(id, true);
    if (mounted) {
      widget.onWorkerSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(content: Text('Đã lưu ${worker.fullName} vào Đội thợ.')),
      );
    }
  }

  Future<void> _paste() async {
    setState(() => _camera = false);
    final text = TextEditingController();
    final form = GlobalKey<FormState>();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dán nội dung mã QR'),
        scrollable: true,
        content: Form(
          key: form,
          child: TextFormField(
            controller: text,
            maxLength: 4096,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Nội dung QR',
              hintText: 'Dán mã đã sao chép hoặc liên kết công trình',
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Dán nội dung mã QR' : null,
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
                Navigator.pop(context, text.text.trim());
              }
            },
            child: const Text('Kiểm tra mã'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    text.dispose();
    if (raw != null && mounted && widget.active) await _scan(raw);
  }

  @override
  Widget build(BuildContext context) => ContentFrame(
    child: RefreshIndicator(
      onRefresh: () async {
        if (_mode == 1 && !widget.worker) {
          await _loadJobs();
        } else {
          setState(() => _error = null);
        }
      },
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: [
              const ButtonSegment(
                value: 0,
                icon: Icon(Icons.qr_code_scanner_rounded),
                label: Text('Quét mã QR'),
              ),
              ButtonSegment(
                value: 1,
                icon: const Icon(Icons.qr_code_rounded),
                label: Text(widget.worker ? 'Mã QR của tôi' : 'QR công trình'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: _busy ? null : (s) => _modeChanged(s.first),
          ),
          const SizedBox(height: 24),
          if (_loading) const ContentSkeleton(compact: true),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Đang xử lý mã QR…'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_mode == 0) ...[
            if (_camera &&
                widget.active &&
                !_busy &&
                (ModalRoute.of(context)?.isCurrent ?? true))
              widget.scannerBuilder?.call(_scan) ?? QrCamera(onCode: _scan)
            else
              Container(
                height: 260,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 96),
                    SizedBox(height: 16),
                    Text('Đưa mã QR vào khung để quét'),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => setState(() => _camera = !_camera),
              icon: Icon(
                _camera
                    ? Icons.videocam_off_outlined
                    : Icons.camera_alt_outlined,
              ),
              label: Text(_camera ? 'Tắt camera' : 'Mở camera quét QR'),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _paste,
              icon: const Icon(Icons.content_paste),
              label: const Text('Dán nội dung mã QR'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Điểm danh công trình · Lưu thợ bằng mã cá nhân · Mở công trình được chia sẻ · Đối chiếu thanh toán VietQR. Camera chỉ hoạt động khi bạn bật chế độ quét.',
            ),
          ] else if (widget.worker) ...[
            if (widget.api.session case final session?)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        session.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: QrAction.workerCode(session.userId),
                        size: 240,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chủ thầu quét mã để lưu hồ sơ của bạn vào Đội thợ. Mã không chứa số điện thoại, mật khẩu hoặc JWT.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text('Đăng nhập lại để hiển thị mã hồ sơ của bạn.'),
          ] else ...[
            if (!_loading && _jobs.isEmpty && _error == null)
              const EmptyState(
                title: 'Chưa có công trình đang hoạt động',
                message: 'Đăng công trình và duyệt thợ để bắt đầu ca làm. QR điểm danh do Backend cấp và hết hạn sau 5 phút.',
              ),
            if (_jobs.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                key: ValueKey(_jobId),
                initialValue: _jobId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Công trình đang hoạt động',
                ),
                items: _jobs
                    .map(
                      (j) => DropdownMenuItem(
                        value: j.id,
                        child: Text(j.title, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _busy ? null : (id) => setState(() => _jobId = id),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy || _loading || _jobId == null
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            ShiftCodeDialog(api: widget.api, jobId: _jobId!),
                      ),
                icon: const Icon(Icons.qr_code),
                label: const Text('Hiển thị QR điểm danh'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mã được tạo mới khi mở, hiệu lực tối đa 5 phút. Chỉ chia sẻ tại công trường; mỗi thợ tự xác nhận giờ vào/ra trên tài khoản của mình.',
              ),
            ],
          ],
        ],
      ),
    ),
  );
}
