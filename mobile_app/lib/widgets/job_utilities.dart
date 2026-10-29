import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/job_links.dart';
import 'app_snack_bar.dart';
import '../screens/crew_screen.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.api,
    required this.id,
    this.worker = false,
  });
  final ApiService api;
  final int id;
  final bool worker;
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _saved = false, _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ids = widget.worker
          ? (await widget.api.savedWorkers()).map((w) => w.id)
          : (await widget.api.savedJobs()).map((j) => j.id);
      if (mounted) setState(() => _saved = ids.contains(widget.id));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (_error != null) {
      await _load();
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.worker) {
        await widget.api.saveWorker(widget.id, !_saved);
      } else {
        await widget.api.saveJob(widget.id, !_saved);
      }
      if (mounted) setState(() => _saved = !_saved);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: Text(e.message), kind: NoticeKind.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _busy ? null : _toggle,
    icon: Icon(
      _error != null
          ? Icons.refresh
          : _saved
          ? Icons.bookmark
          : Icons.bookmark_border,
    ),
    label: Text(
      _busy
          ? 'Đang cập nhật…'
          : _error != null
          ? 'Tải lại mục đã lưu'
          : _saved
          ? 'Đã lưu'
          : widget.worker
          ? 'Lưu thợ quen'
          : 'Lưu công trình',
    ),
  );
}

class JobUtilities extends StatelessWidget {
  const JobUtilities({super.key, required this.job, this.api});
  final Job job;
  final ApiService? api;
  Future<void> _navigate(BuildContext context) async {
    try {
      if (await launchUrl(
        JobLinks.directions(job),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: const Text('Không mở được bản đồ. Hãy thử lại.'),
          kind: NoticeKind.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (api?.session?.role == 'ROLE_WORKER')
        FavoriteButton(api: api!, id: job.id),
      if (api?.session?.role == 'ROLE_WORKER' &&
          job.startsOn != null &&
          ['OPEN', 'IN_PROGRESS'].contains(job.status))
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CrewScreen(api: api!, job: job),
            ),
          ),
          icon: const Icon(Icons.groups_outlined),
          label: const Text('Ứng tuyển tổ đội'),
        ),
      OutlinedButton.icon(
        onPressed: () => _navigate(context),
        icon: const Icon(Icons.directions_outlined),
        label: const Text('Chỉ đường'),
      ),
      OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chia sẻ công trình'),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(job.title, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Mã QR liên kết công trình',
                    child: QrImageView(
                      data: JobLinks.share(job.id).toString(),
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(JobLinks.share(job.id).toString()),
                  const SizedBox(height: 8),
                  const Text(
                    'Người nhận đăng nhập để xem và ứng tuyển.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: JobLinks.share(job.id).toString()),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppSnackBar(
                        content: const Text('Đã sao chép liên kết công trình.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Sao chép link'),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Chia sẻ'),
      ),
    ],
  );
}
