import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'app_snack_bar.dart';
import 'bouncing_button.dart';

class RoleSwitchTile extends StatefulWidget {
  const RoleSwitchTile({
    super.key,
    required this.api,
    this.enabled = true,
    this.onBusy,
  });
  final ApiService api;
  final bool enabled;
  final ValueChanged<bool>? onBusy;
  @override
  State<RoleSwitchTile> createState() => _RoleSwitchTileState();
}

class _RoleSwitchTileState extends State<RoleSwitchTile> {
  bool _busy = false;
  String? _error;
  Future<void> _switch(bool worker) async {
    if (_busy || !widget.enabled) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(worker ? 'Chuyển sang Chủ thầu?' : 'Chuyển sang Thợ xây?'),
        content: Text(
          'Hồ sơ, ảnh, số dư ví và lịch sử vẫn thuộc cùng tài khoản. Chỉ chuyển khi đã xử lý xong công việc và thanh toán.\n\n${worker ? 'Bạn sẽ tạm ngưng nhận việc mới khi dùng vai trò Chủ thầu.' : 'Khi vào giao diện Thợ, hãy bật trạng thái nhận việc khi bạn sẵn sàng.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chuyển vai trò'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AppHaptics.light();
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusy?.call(true);
    try {
      await widget.api.switchRole(worker ? 'ROLE_CONTRACTOR' : 'ROLE_WORKER');
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: Text(
            worker
                ? 'Đã chuyển sang vai trò Chủ thầu.'
                : 'Đã chuyển sang vai trò Thợ xây.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Chưa chuyển được vai trò. Kiểm tra kết nối và thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusy?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.api.session?.role;
    if (role != 'ROLE_WORKER' && role != 'ROLE_CONTRACTOR') {
      return const SizedBox.shrink();
    }
    final worker = role == 'ROLE_WORKER';
    final color = worker ? AppTheme.contractorBlue : AppTheme.workerAmber;
    return Card(
      color: AppPalette.of(context).outdoor
          ? AppPalette.of(context).surface
          : color.withValues(alpha: AppPalette.of(context).dark ? .16 : .06),
      child: Column(
        children: [
          BouncingButton(
            enabled: widget.enabled && !_busy,
            child: ListTile(
              leading: Icon(
                Icons.swap_horiz_rounded,
                color: AppPalette.of(context).ink,
              ),
              title: Text(
                worker
                    ? 'Chuyển sang vai trò Chủ thầu'
                    : 'Chuyển sang vai trò Thợ xây',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                _busy
                    ? 'Đang chuyển giao diện…'
                    : 'Giữ nguyên tài khoản, hồ sơ và ví',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.enabled && !_busy ? () => _switch(worker) : null,
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: AppPalette.of(context).errorStrong),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
