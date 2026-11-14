import 'package:image_picker/image_picker.dart';

import '../services/device_photo_picker.dart';
import '../widgets/user_avatar.dart';
import '../widgets/photo_preview_dialog.dart';
import '../widgets/bouncing_button.dart';
import 'settings_screen.dart';
import '../widgets/account_security_sheet.dart';
import '../widgets/saved_workers_preview.dart';
import '../widgets/home_navigation.dart';
import 'incidents_screen.dart';
import '../widgets/portfolio_uploads.dart';
import 'saved_screen.dart';
import 'crew_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/design_motion.dart';
import 'calendar_screen.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/app_snack_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/kyc_camera.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/profile_editor.dart';
import '../widgets/portfolio_gallery.dart';
import '../widgets/profile_summary.dart';
import '../widgets/kyc_scanner_frame.dart';
import 'leaderboard_screen.dart';
import 'reputation_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.api,
    this.camera,
    this.photoPicker,
    this.embedded = false,
    this.accountDetails = false,
  });
  final ApiService api;
  final bool accountDetails;
  final bool embedded;
  final KycCamera? camera;
  final DevicePhotoPicker? photoPicker;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  KycPhoto? _frontImage, _backImage;
  KycCamera get _camera => widget.camera ?? KycCamera.instance;
  UserProfile? _profile;
  bool _loading = false;
  bool _editingKyc = false;
  bool _avatarBusy = false;
  bool _avatarUploading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.api.profile();
      final recovered = await _camera.recover(profile.id);
      if (mounted) {
        setState(() {
          _profile = profile;
          if (recovered != null) {
            _editingKyc = true;
            if (recovered.face == 'front') {
              _frontImage = recovered.photo;
            } else {
              _backImage = recovered.photo;
            }
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_frontImage == null || _backImage == null) {
      setState(
        () => _error = 'Hãy chụp đủ mặt trước và mặt sau CCCD trước khi gửi.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.api.uploadCccd(_frontImage!, _backImage!);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _frontImage = null;
        _backImage = null;
        _editingKyc = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: const Text(
            'Đã cập nhật đủ hai ảnh CCCD. Vui lòng chờ quản trị viên xác thực.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _capture(String face) async {
    if (_profile == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final photo = await _camera.capture(_profile!.id, face);
      if (mounted && photo != null) {
        setState(() {
          if (face == 'front') {
            _frontImage = photo;
          } else {
            _backImage = photo;
          }
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(
          () => _error = 'Không mở được camera. Hãy cho phép truy cập camera trong Cài đặt rồi thử lại.',
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Không đọc được ảnh. Vui lòng chụp lại.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _photoCard(String face, String label, KycPhoto? photo) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          KycScannerFrame(label: label, photo: photo),
          if (photo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Bấm ảnh để phóng to kiểm tra trước khi gửi.',
                style: TextStyle(color: AppPalette.of(context).muted),
              ),
            ),
          const SizedBox(height: 12),
          if (photo == null &&
              (face == 'front'
                      ? _profile?.cccdFrontImage
                      : _profile?.cccdBackImage) !=
                  null)
            const Text('Đã có ảnh trong hồ sơ. Chụp ảnh mới để thay thế.'),
          OutlinedButton.icon(
            key: ValueKey('capture-$face'),
            onPressed: _loading ? null : () => _capture(face),
            icon: Icon(
              _camera.usesFileSelection
                  ? Icons.upload_file
                  : Icons.camera_alt_outlined,
            ),
            label: Text(
              '${_camera.usesFileSelection ? 'Chọn ảnh' : 'Chụp'} ${face == 'front' ? 'mặt trước' : 'mặt sau'}',
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _avatar() async {
    if (_avatarBusy || _loading) return;
    setState(() => _avatarBusy = true);
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        useSafeArea: true,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      );
      if (source == null || !mounted) return;
      final bytes = await (widget.photoPicker ?? DevicePhotoPicker()).pick(
        source,
      );
      if (bytes == null || !mounted) return;
      final confirmed = await showDialog<String>(
        context: context,
        builder: (_) => PhotoPreviewDialog(
          bytes: bytes,
          title: 'Xác nhận ảnh đại diện',
          showCaption: false,
          confirmLabel: 'Dùng ảnh này',
        ),
      );
      if (confirmed == null || !mounted) return;
      setState(() => _avatarUploading = true);
      final profile = await widget.api.uploadAvatar(bytes);
      if (mounted) {
        setState(() {
          _profile = profile;
          _error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(content: const Text('Đã cập nhật ảnh đại diện.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Không mở được ảnh. Kiểm tra quyền camera/thư viện rồi thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _avatarBusy = false;
          _avatarUploading = false;
        });
      }
    }
  }

  Future<void> _edit() async {
    if (_profile == null || _loading || _avatarBusy) return;
    bool busy = false;
    final profile = await showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => PopScope(
          canPop: !busy,
          child: FractionallySizedBox(
            heightFactor: .9,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chỉnh sửa thông tin',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: busy ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: ProfileEditor(
                        api: widget.api,
                        profile: _profile!,
                        onBusy: (value) => setSheetState(() => busy = value),
                        onSaved: (person) => Navigator.pop(context, person),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (profile != null && mounted) setState(() => _profile = profile);
  }

  Widget _utilities() => Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tiện ích nghề nghiệp',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final item in <(IconData, String, Widget)>[
          if (_profile!.role == 'ROLE_WORKER') ...[
            (
              Icons.calendar_month_outlined,
              'Lịch làm việc',
              CalendarScreen(api: widget.api),
            ),
            (
              Icons.groups_outlined,
              'Tổ đội của tôi',
              CrewScreen(api: widget.api),
            ),
            (
              Icons.bookmarks_outlined,
              'Công trình yêu thích',
              SavedScreen(api: widget.api, worker: true),
            ),
            (
              Icons.history,
              'Lịch sử uy tín',
              ReputationScreen(api: widget.api),
            ),
          ] else
            (
              Icons.groups_outlined,
              'Thợ quen',
              SavedScreen(api: widget.api, worker: false),
            ),
          (
            Icons.leaderboard_outlined,
            'Bảng xếp hạng thợ',
            LeaderboardScreen(api: widget.api),
          ),
          (
            Icons.health_and_safety_outlined,
            'Sự cố đã gửi',
            IncidentsScreen(api: widget.api),
          ),
        ])
          BouncingButton(
            child: ListTile(
              leading: Icon(item.$1),
              title: Text(item.$2),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => item.$3)),
            ),
          ),
      ],
    ),
  );
  Widget _personal() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thông tin cá nhân & kinh nghiệm',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(_profile!.fullName),
          Text(
            _profile!.phoneNumber,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text('${_profile!.experienceYears} năm kinh nghiệm'),
          if (_profile!.experienceSummary.isNotEmpty)
            Text(
              _profile!.experienceSummary,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (_profile!.skills.isNotEmpty)
            Text(
              'Kỹ năng: ${_profile!.skills.join(' · ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading || _avatarBusy ? null : _edit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Chỉnh sửa thông tin'),
          ),
          TextButton.icon(
            onPressed: _loading || _avatarBusy
                ? null
                : () async {
                    await showAccountSecuritySheet(
                      context,
                      widget.api,
                      phone: true,
                    );
                    if (mounted) _load();
                  },
            icon: const Icon(Icons.phone_outlined, size: 18),
            label: const Text('Đổi số điện thoại'),
          ),
        ],
      ),
    ),
  );
  Widget _kyc() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Xác thực CCCD',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      if (_profile!.verified && !_editingKyc)
        Card(
          child: ListTile(
            leading: Icon(
              Icons.verified_outlined,
              color: AppPalette.of(context).successStrong,
            ),
            title: const Text(
              'Định danh CCCD: Đã xác thực',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            trailing: TextButton(
              key: const ValueKey('edit-verified-kyc'),
              onPressed: _loading
                  ? null
                  : () => setState(() => _editingKyc = true),
              child: const Text('Cập nhật'),
            ),
          ),
        ),
      if (!_profile!.verified || _editingKyc) ...[
        if (_profile!.verified)
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ảnh mới cần được Admin xác thực lại.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _editingKyc = false;
                        _frontImage = null;
                        _backImage = null;
                        _error = null;
                      }),
                child: const Text('Hủy cập nhật'),
              ),
            ],
          ),
        const Text(
          'Chụp rõ toàn bộ CCCD, đủ sáng, tránh lóa và không che thông tin. Hệ thống kiểm tra tệp ảnh tự động; quản trị viên đối chiếu danh tính trước khi xác thực. Mỗi lần gửi cần đủ hai ảnh mới.',
        ),
        const SizedBox(height: 16),
        _photoCard('front', 'Mặt trước CCCD', _frontImage),
        const SizedBox(height: 16),
        _photoCard('back', 'Mặt sau CCCD', _backImage),
        const SizedBox(height: 16),
        BouncingButton(
          child: FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: const Icon(Icons.badge_outlined),
            label: const Text('Cập nhật CCCD'),
          ),
        ),
      ],
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded
        ? null
        : AppBar(
            title: Text(
              widget.accountDetails
                  ? 'Thông tin cá nhân & KYC'
                  : 'Hồ sơ của tôi',
            ),
            actions: [
              if (!widget.accountDetails) ...[
                HomeInboxActions(api: widget.api),
                IconButton(
                  tooltip: 'Cài đặt',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(api: widget.api),
                      ),
                    );
                    if (mounted && widget.api.session != null) _load();
                  },
                ),
              ],
            ],
          ),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loading && _profile == null) const ContentSkeleton(),
              if (_profile != null) ...[
                ProfileSummary(
                  name: _profile!.fullName,
                  phone: _profile!.phoneNumber,
                  worker: _profile!.role == 'ROLE_WORKER',
                  rating: _profile!.rating,
                  score: _profile!.reputationScore,
                  completed: _profile!.completedJobs,
                  tier: _profile!.workerTier ?? 'SILVER',
                  verified: _profile!.verified,
                  avatar: UserAvatar(
                    api: widget.api,
                    name: _profile!.fullName,
                    path: _profile!.avatarUrl,
                  ),
                  onAvatarTap: _loading || _avatarBusy ? null : _avatar,
                ),
                TextButton.icon(
                  onPressed: _loading || _avatarBusy ? null : _avatar,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(
                    _avatarUploading
                        ? 'Đang cập nhật ảnh…'
                        : 'Đổi ảnh đại diện',
                  ),
                ),
                if (_loading || _avatarUploading)
                  const LinearProgressIndicator(),
                const SizedBox(height: 16),
                if (!widget.accountDetails) ...[
                  _utilities(),
                  const SizedBox(height: 16),
                ],
                _personal(),
                const SizedBox(height: 16),
                _kyc(),
                if (!widget.accountDetails) ...[
                  const SizedBox(height: 24),
                  PortfolioUploads(
                    api: widget.api,
                    ownerId: _profile!.id,
                    editable: true,
                  ),
                  if (_profile!.projectImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PortfolioGallery(images: _profile!.projectImages),
                  ],
                  if (_profile!.role == 'ROLE_CONTRACTOR')
                    SavedWorkersPreview(api: widget.api),
                ],
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
