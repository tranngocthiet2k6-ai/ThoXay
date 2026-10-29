import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'tier_badge.dart';

class HeroGreeting extends StatefulWidget {
  const HeroGreeting({
    super.key,
    required this.api,
    required this.title,
    required this.subtitle,
    this.availability,
    this.onAvailabilityChanged,
  });
  final ApiService api;
  final String title, subtitle;
  final bool? availability;
  final ValueChanged<bool>? onAvailabilityChanged;
  @override
  State<HeroGreeting> createState() => _HeroGreetingState();
}

class _HeroGreetingState extends State<HeroGreeting> {
  UserProfile? _profile;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.api.session == null) return;
    try {
      final profile = await widget.api.profile();
      if (mounted) setState(() => _profile = profile);
    } on ApiException {
      /* A failed greeting must not block job discovery. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.fullName ?? widget.api.session?.fullName ?? 'bạn';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: AppTheme.brandGradient(context),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Text(
                  name.isEmpty ? 'TX' : name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào $name,',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Cùng xây những kết nối bền vững',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_profile?.role == 'ROLE_WORKER') ...[
            const SizedBox(height: 12),
            TierBadge(tier: _profile!.workerTier ?? 'SILVER'),
          ],
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          if (widget.api.session?.role == 'ROLE_WORKER' ||
              widget.availability != null) ...[
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              child: SwitchListTile(
                key: const ValueKey('availability-switch'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                secondary: Icon(
                  widget.availability == true
                      ? Icons.wifi_rounded
                      : Icons.pause_circle_outline,
                  color: widget.availability == true
                      ? const Color(0xff059669)
                      : const Color(0xff64748b),
                ),
                title: Text(
                  widget.availability == true
                      ? 'Đang nhận việc'
                      : widget.availability == false
                      ? 'Tạm ngưng nhận việc'
                      : 'Đang đồng bộ trạng thái',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                value: widget.availability == true,
                onChanged: widget.onAvailabilityChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
