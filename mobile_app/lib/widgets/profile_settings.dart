import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/device_preferences.dart';
import '../services/push_notifications.dart';
import '../screens/profile_screen.dart';
import '../screens/support_center_screen.dart';
import '../screens/incidents_screen.dart';
import '../theme/appearance_controller.dart';
import '../theme/app_theme.dart';
import 'account_security_sheet.dart';
import 'app_snack_bar.dart';
import 'bouncing_button.dart';
import 'app_information.dart';
import 'legal_information.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key, required this.api, this.push});
  final ApiService api;
  final PushClient? push;
  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final _preferences = DevicePreferences.instance;
  bool? _jobs, _chat;
  bool _busy = false;
  String? _pushError;
  static const _supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '0339971407',
  );
  @override
  void initState() {
    super.initState();
    _loadPush();
  }

  void _notice(String text, {bool error = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: Text(text),
          kind: error ? NoticeKind.error : NoticeKind.info,
        ),
      );
    }
  }

  Future<void> _loadPush() async {
    try {
      final value = await widget.api.notificationPreferences();
      if (mounted) {
        setState(() {
          _jobs = value['jobPushEnabled'];
          _chat = value['chatPushEnabled'];
          _pushError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _pushError =
              'Chưa tải được lựa chọn thông báo. Kiểm tra kết nối rồi thử lại.',
        );
      }
    }
  }

  Future<void> _push({bool? jobs, bool? chat}) async {
    if (_busy || _jobs == null || _chat == null) return;
    setState(() => _busy = true);
    try {
      final nextJobs = jobs ?? _jobs!, nextChat = chat ?? _chat!;
      await widget.api.setNotificationPreferences(
        jobs: nextJobs,
        chat: nextChat,
      );
      if (!mounted) return;
      setState(() {
        _jobs = nextJobs;
        _chat = nextChat;
      });
      if (jobs == true || chat == true) {
        _notice(
          await (widget.push ?? PushNotifications.instance).enable(widget.api),
        );
      } else {
        _notice('Đã lưu lựa chọn. Lịch sử trong ứng dụng vẫn được giữ.');
      }
    } on ApiException catch (e) {
      _notice(e.message, error: true);
    } catch (_) {
      _notice('Chưa lưu được lựa chọn. Vui lòng thử lại.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mode(DisplayMode mode) async {
    AppHaptics.light();
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance != null && !await appearance.setMode(mode)) {
      _notice('Đã đổi giao diện; chưa lưu được trên thiết bị.', error: true);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất khỏi Thợ Xây?'),
        content: const Text(
          'Bạn có thể đăng nhập lại bất cứ lúc nào. Công việc và số dư của bạn vẫn được giữ trên hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    AppHaptics.light();
    try {
      await widget.api.logout();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  Widget _row(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) => BouncingButton(
    enabled: onTap != null,
    child: ListTile(
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppPalette.of(context).soft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 21, color: AppPalette.of(context).muted),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    ),
  );
  Widget _group(String title, List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 72, endIndent: 16),
              rows[i],
            ],
          ],
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    return ListenableBuilder(
      listenable: _preferences,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _group('Tài khoản & Bảo mật', [
            _row(
              Icons.person_outline,
              'Thông tin cá nhân & KYC',
              subtitle: 'Họ tên, số điện thoại và định danh CCCD',
              onTap: () =>
                  _open(ProfileScreen(api: widget.api, accountDetails: true)),
            ),
            _row(
              Icons.lock_outline,
              'Đổi mật khẩu',
              subtitle: 'Bảo vệ tài khoản và thu hồi phiên cũ',
              onTap: () => showAccountSecuritySheet(context, widget.api),
            ),
          ]),
          _group('Hiển thị & Trải nghiệm công trường', [
            _row(
              Icons.dark_mode_outlined,
              'Giao diện Sáng / Tối',
              subtitle: appearance?.mode == DisplayMode.dark
                  ? 'Đang dùng giao diện Tối'
                  : 'Đang dùng giao diện Sáng',
              trailing: Switch(
                value: appearance?.mode == DisplayMode.dark,
                onChanged: appearance == null
                    ? null
                    : (value) =>
                          _mode(value ? DisplayMode.dark : DisplayMode.light),
              ),
              onTap: appearance == null
                  ? null
                  : () => _mode(
                      appearance.mode == DisplayMode.dark
                          ? DisplayMode.light
                          : DisplayMode.dark,
                    ),
            ),
            _row(
              Icons.wb_sunny_outlined,
              'Tương phản cao (Ngoài trời)',
              subtitle: 'Chữ và nút rõ hơn dưới ánh nắng',
              trailing: Switch(
                value: appearance?.mode == DisplayMode.outdoor,
                onChanged: appearance == null
                    ? null
                    : (value) => _mode(
                        value ? DisplayMode.outdoor : DisplayMode.light,
                      ),
              ),
              onTap: appearance == null
                  ? null
                  : () => _mode(
                      appearance.mode == DisplayMode.outdoor
                          ? DisplayMode.light
                          : DisplayMode.outdoor,
                    ),
            ),
            _row(
              Icons.vibration_outlined,
              'Rung phản hồi xúc giác',
              subtitle: 'Rung nhẹ khi thao tác trên thiết bị hỗ trợ',
              trailing: Switch(
                value: _preferences.haptics,
                onChanged: _busy
                    ? null
                    : (value) async {
                        setState(() => _busy = true);
                        if (!await _preferences.setHaptics(value)) {
                          _notice('Chưa lưu được lựa chọn rung.', error: true);
                        }
                        if (value) AppHaptics.light();
                        if (mounted) setState(() => _busy = false);
                      },
              ),
            ),
          ]),
          _group('Thông báo & Khu vực', [
            _row(
              Icons.work_outline,
              'Thông báo công việc',
              subtitle: _jobs == null
                  ? 'Đang chờ lựa chọn từ máy chủ'
                  : 'Đơn ứng tuyển và thay đổi công trình',
              trailing: Switch(
                value: _jobs ?? false,
                onChanged: _busy || _jobs == null
                    ? null
                    : (value) => _push(jobs: value),
              ),
            ),
            _row(
              Icons.chat_bubble_outline,
              'Thông báo tin nhắn',
              subtitle: _chat == null
                  ? 'Đang chờ lựa chọn từ máy chủ'
                  : 'Thông báo đẩy từ người đang trao đổi',
              trailing: Switch(
                value: _chat ?? false,
                onChanged: _busy || _chat == null
                    ? null
                    : (value) => _push(chat: value),
              ),
            ),
            if (_pushError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_pushError!),
                    TextButton(
                      onPressed: _loadPush,
                      child: const Text('Tải lại lựa chọn'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bán kính tìm việc mặc định',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Áp dụng khi mở khu vực tìm việc mới. Không thay đổi phạm vi chấm công 200m.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final radius in DevicePreferences.radii)
                        ChoiceChip(
                          label: Text('${radius.toInt()} km'),
                          selected: _preferences.radius == radius,
                          onSelected: _busy
                              ? null
                              : (_) async {
                                  setState(() => _busy = true);
                                  if (!await _preferences.setRadius(radius)) {
                                    _notice(
                                      'Chưa lưu được bán kính.',
                                      error: true,
                                    );
                                  }
                                  if (mounted) setState(() => _busy = false);
                                },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Thông báo đẩy cần quyền của điện thoại và cấu hình Firebase. Thông báo tài chính, KYC và an toàn được quản lý riêng; lịch sử luôn có trong ứng dụng.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ]),
          _group('Hỗ trợ & Pháp lý', [
            _row(
              Icons.support_agent_outlined,
              'Trung tâm trợ giúp & SOS',
              subtitle: 'Hướng dẫn, yêu cầu hỗ trợ và an toàn',
              onTap: () => _open(SupportCenterScreen(api: widget.api)),
            ),
            if (_supportPhone.isNotEmpty)
              _row(
                Icons.phone_outlined,
                'Hotline hỗ trợ',
                subtitle: _supportPhone,
                onTap: () async {
                  try {
                    if (!await launchUrl(
                      Uri(scheme: 'tel', path: _supportPhone),
                    )) {
                      _notice(
                        'Không mở được ứng dụng gọi điện. Số hỗ trợ: $_supportPhone',
                        error: true,
                      );
                    }
                  } catch (_) {
                    _notice(
                      'Không mở được ứng dụng gọi điện. Số hỗ trợ: $_supportPhone',
                      error: true,
                    );
                  }
                },
              ),
            _row(
              Icons.health_and_safety_outlined,
              'Theo dõi sự cố & khiếu nại',
              onTap: () => _open(IncidentsScreen(api: widget.api)),
            ),
            _row(
              Icons.description_outlined,
              'Điều khoản sử dụng',
              onTap: () => showLegalInformation(context, privacy: false),
            ),
            _row(
              Icons.privacy_tip_outlined,
              'Chính sách bảo mật',
              onTap: () => showLegalInformation(context, privacy: true),
            ),
            _row(
              Icons.perm_device_information_outlined,
              'Quyền truy cập & dữ liệu',
              onTap: () => showDataInformation(context),
            ),
          ]),
          const SizedBox(height: 32),
          BouncingButton(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.of(context).errorStrong,
              ),
              onPressed: _busy ? null : _logout,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Đăng xuất'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thợ Xây v${AppRelease.name}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
