import '../theme/app_theme.dart';
import '../widgets/design_motion.dart';
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
  const ProfileScreen({super.key, required this.api, this.camera});
  final ApiService api;
  final KycCamera? camera;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  KycPhoto? _frontImage, _backImage;
  KycCamera get _camera => widget.camera ?? KycCamera.instance;
  UserProfile? _profile;
  bool _loading = false;
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
      });
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: Text(
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
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Bấm ảnh để phóng to kiểm tra trước khi gửi.',
                style: TextStyle(color: AppColors.muted),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hồ sơ & xác thực CCCD'),
      actions: [
        IconButton(
          tooltip: 'Làm mới hồ sơ',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ContentFrame(
      child: RefreshIndicator(
        onRefresh: () async {
          if (!_loading) await _load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionIntro(
                title: 'Hồ sơ của bạn',
                subtitle: 'Một hồ sơ rõ ràng giúp kết nối đúng người.',
                eyebrow: 'TÀI KHOẢN',
              ),
              if (_loading && _profile == null) const ContentSkeleton(),
              if (_loading && _profile != null) const LinearProgressIndicator(),
              if (_profile != null) ...[
                ProfileSummary(
                  name: _profile!.fullName,
                  worker: _profile!.role == 'ROLE_WORKER',
                  rating: _profile!.rating,
                  score: _profile!.reputationScore,
                  completed: _profile!.completedJobs,
                  tier: _profile!.workerTier ?? 'SILVER',
                  verified: _profile!.verified,
                ),
                const SizedBox(height: 16),
                Text(_profile!.phoneNumber),
                if (_profile!.role == 'ROLE_WORKER')
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReputationScreen(api: widget.api),
                      ),
                    ),
                    icon: const Icon(Icons.history),
                    label: const Text('Lịch sử uy tín'),
                  ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LeaderboardScreen(api: widget.api),
                    ),
                  ),
                  icon: const Icon(Icons.leaderboard_outlined),
                  label: const Text('Bảng xếp hạng thợ'),
                ),
                const SizedBox(height: 8),
                if (_profile!.role == 'ROLE_WORKER')
                  Text(
                    _profile!.completedJobs == 0
                        ? 'Chưa có đánh giá công trình'
                        : 'Đánh giá trung bình: ${_profile!.rating.toStringAsFixed(1)}/5',
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: Icon(
                      _profile!.verified
                          ? Icons.verified
                          : Icons.hourglass_empty,
                    ),
                    label: Text(
                      _profile!.verified
                          ? 'Đã xác thực CCCD'
                          : 'Chưa xác thực CCCD',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ExpansionTile(
                    maintainState: true,
                    enabled: !_loading,
                    title: const Text('Thông tin cá nhân & kinh nghiệm'),
                    leading: const Icon(Icons.edit_outlined),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      ProfileEditor(
                        api: widget.api,
                        profile: _profile!,
                        onBusy: (busy) {
                          if (mounted) setState(() => _loading = busy);
                        },
                        onSaved: (person) => setState(() => _profile = person),
                      ),
                    ],
                  ),
                ),
                if (_profile!.projectImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PortfolioGallery(images: _profile!.projectImages),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Chụp rõ toàn bộ CCCD, đủ sáng, tránh lóa và không che thông tin. Hệ thống kiểm tra tệp ảnh tự động; quản trị viên đối chiếu danh tính trước khi xác thực. Mỗi lần gửi cần đủ hai ảnh mới.',
                ),
                const SizedBox(height: 16),
                _photoCard('front', 'Mặt trước CCCD', _frontImage),
                const SizedBox(height: 16),
                _photoCard('back', 'Mặt sau CCCD', _backImage),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Cập nhật CCCD'),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
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
  );
}
