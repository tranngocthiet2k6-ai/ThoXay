import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/profile_editor.dart';
import '../widgets/portfolio_gallery.dart';
import '../widgets/tier_badge.dart';
import 'leaderboard_screen.dart';
import 'reputation_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _frontImage = TextEditingController();
  final _backImage = TextEditingController();
  UserProfile? _profile;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _frontImage.dispose();
    _backImage.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.api.profile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _frontImage.text = profile.cccdFrontImage ?? '';
          _backImage.text = profile.cccdBackImage ?? '';
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.api.updateCccd(
        _frontImage.text.trim(),
        _backImage.text.trim(),
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_profile != null) ...[
            Text(
              _profile!.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_profile!.phoneNumber),
            if (_profile!.role == 'ROLE_WORKER') ...[
              TierBadge(tier: _profile!.workerTier ?? 'SILVER'),
              Text(
                '${_profile!.reputationScore}/100 điểm uy tín · ${_profile!.completedJobs} công trình hoàn thành',
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReputationScreen(api: widget.api),
                  ),
                ),
                icon: const Icon(Icons.history),
                label: const Text('Lịch sử uy tín'),
              ),
            ],
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
                  _profile!.verified ? Icons.verified : Icons.hourglass_empty,
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
              'Cung cấp đủ ảnh mặt trước và mặt sau CCCD bằng liên kết HTTPS. Mỗi lần cập nhật cần được quản trị viên xác thực lại.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    key: const ValueKey('cccd-front-input'),
                    controller: _frontImage,
                    enabled: !_loading,
                    maxLength: 500,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Liên kết ảnh mặt trước CCCD (HTTPS)',
                    ),
                    validator: (v) =>
                        RegExp(r'^https://[^\s]+$').hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Nhập liên kết HTTPS hợp lệ cho mặt trước',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('cccd-back-input'),
                    controller: _backImage,
                    enabled: !_loading,
                    maxLength: 500,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Liên kết ảnh mặt sau CCCD (HTTPS)',
                    ),
                    validator: (v) =>
                        RegExp(r'^https://[^\s]+$').hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Nhập liên kết HTTPS hợp lệ cho mặt sau',
                  ),
                ],
              ),
            ),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    ),
  );
}
