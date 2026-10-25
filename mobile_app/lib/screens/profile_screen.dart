import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _image = TextEditingController();
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
    _image.dispose();
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
          _image.text = profile.cccdImage ?? '';
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
      final profile = await widget.api.updateCccd(_image.text.trim());
      if (!mounted) return;
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã cập nhật ảnh CCCD. Vui lòng chờ quản trị viên xác thực.',
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
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (_profile != null) ...[
          Text(
            _profile!.fullName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_profile!.phoneNumber),
          const SizedBox(height: 8),
          Text('Đánh giá trung bình: ${_profile!.rating.toStringAsFixed(1)}/5'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                _profile!.verified ? Icons.verified : Icons.hourglass_empty,
              ),
              label: Text(
                _profile!.verified ? 'Đã xác thực CCCD' : 'Chưa xác thực CCCD',
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cập nhật liên kết ảnh CCCD HTTPS để quản trị viên kiểm tra. Mỗi lần cập nhật cần được xác thực lại.',
          ),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: TextFormField(
              controller: _image,
              enabled: !_loading,
              maxLength: 500,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Liên kết ảnh CCCD HTTPS',
              ),
              validator: (v) =>
                  RegExp(r'^https://[^\s]+$').hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Nhập liên kết HTTPS hợp lệ',
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
  );
}
