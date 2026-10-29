import 'app_snack_bar.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.api,
    required this.profile,
    required this.onSaved,
    required this.onBusy,
  });
  final ApiService api;
  final UserProfile profile;
  final ValueChanged<UserProfile> onSaved;
  final ValueChanged<bool> onBusy;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _birth = TextEditingController(),
      _years = TextEditingController();
  final _summary = TextEditingController(),
      _skills = TextEditingController(),
      _images = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _populate(widget.profile);
  }

  void _populate(UserProfile person) {
    _name.text = person.fullName;
    _birth.text = person.dateOfBirth ?? '';
    _years.text = '${person.experienceYears}';
    _summary.text = person.experienceSummary;
    _skills.text = person.skills.join(', ');
    _images.text = person.projectImages.join('\n');
  }

  @override
  void didUpdateWidget(covariant ProfileEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_busy && oldWidget.profile != widget.profile) {
      _populate(widget.profile);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _birth, _years, _summary, _skills, _images]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _parts(String input, String pattern) => input
      .split(RegExp(pattern))
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList();
  Future<void> _date() async {
    final first = DateTime(1900);
    final last = DateTime.now().subtract(const Duration(days: 1));
    final selected = DateTime.tryParse(_birth.text) ?? DateTime(1995);
    final value = await showDatePicker(
      context: context,
      initialDate: selected.isBefore(first)
          ? first
          : selected.isAfter(last)
          ? last
          : selected,
      firstDate: first,
      lastDate: last,
    );
    if (value != null && mounted) {
      setState(() => _birth.text = value.toIso8601String().substring(0, 10));
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusy(true);
    try {
      final person = await widget.api.updateProfile(
        fullName: _name.text.trim(),
        dateOfBirth: _birth.text.isEmpty ? null : _birth.text,
        experienceYears: int.parse(_years.text),
        experienceSummary: _summary.text.trim(),
        skills: _parts(_skills.text, r'[,\n]'),
        projectImages: _parts(_images.text, r'\n'),
      );
      if (!mounted) return;
      _populate(person);
      widget.onSaved(person);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: Text(
            'Đã lưu hồ sơ. Thay đổi họ tên hoặc ngày sinh cần được xác thực lại CCCD.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusy(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Đổi họ tên hoặc ngày sinh sẽ cần quản trị viên xác thực lại CCCD.',
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('profile-name'),
          controller: _name,
          enabled: !_busy,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Họ và tên'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Nhập họ và tên' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _birth,
          readOnly: true,
          onTap: _busy ? null : _date,
          decoration: InputDecoration(
            labelText: 'Ngày sinh (không bắt buộc)',
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            suffixIcon: IconButton(
              tooltip: 'Xóa ngày sinh',
              onPressed: _busy ? null : () => setState(_birth.clear),
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('profile-years'),
          controller: _years,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số năm kinh nghiệm'),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 0 || n > 60
                ? 'Nhập số năm từ 0 đến 60'
                : null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _summary,
          enabled: !_busy,
          minLines: 2,
          maxLines: 5,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Kinh nghiệm và công việc đã thực hiện',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('profile-skills'),
          controller: _skills,
          enabled: !_busy,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Kỹ năng',
            helperText: 'Phân cách bằng dấu phẩy, tối đa 20 kỹ năng.',
          ),
          validator: (v) {
            final values = _parts(v ?? '', r'[,\n]');
            return values.length > 20 || values.any((s) => s.length > 50)
                ? 'Tối đa 20 kỹ năng, mỗi kỹ năng 50 ký tự'
                : null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('profile-images'),
          controller: _images,
          enabled: !_busy,
          minLines: 2,
          maxLines: 6,
          maxLength: 5100,
          decoration: const InputDecoration(
            labelText: 'Ảnh dự án (liên kết HTTPS)',
            helperText: 'Mỗi dòng một ảnh, tối đa 10 ảnh. Không dùng ảnh CCCD.',
          ),
          validator: (v) {
            final values = _parts(v ?? '', r'\n');
            return values.length > 10 ||
                    values.any(
                      (s) =>
                          s.length > 500 ||
                          !RegExp(r'^https://[^\s]+$').hasMatch(s),
                    )
                ? 'Dùng tối đa 10 liên kết HTTPS, mỗi liên kết 500 ký tự'
                : null;
          },
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_busy ? 'Đang lưu…' : 'Lưu hồ sơ'),
        ),
      ],
    ),
  );
}
