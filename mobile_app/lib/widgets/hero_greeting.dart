import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import 'server_connection_notice.dart';
import 'tier_badge.dart';
import 'commercial_hero.dart';
import 'bouncing_button.dart';
import '../theme/app_theme.dart';

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
      final person = await widget.api.profile();
      if (mounted) setState(() => _profile = person);
    } on ApiException {
      /* Greeting must never block job discovery. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker =
        widget.api.session?.role == 'ROLE_WORKER' ||
        widget.availability != null;
    final name = _profile?.fullName ?? widget.api.session?.fullName ?? 'bạn';
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ServerConnectionNotice(api: widget.api),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresenceAvatar(
                name: name,
                online: worker ? widget.availability : null,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker
                          ? 'THỢ XÂY • DÀNH CHO THỢ'
                          : 'THỢ XÂY • DÀNH CHO CHỦ THẦU',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: .6,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chào ${name.trim().split(' ').last}!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 22),
                    ),
                    if (worker && _profile?.workerTier != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TierBadge(tier: _profile!.workerTier!),
                      ),
                    if (!worker)
                      Text(
                        widget.title,
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                  ],
                ),
              ),
              if (worker)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Switch(
                      key: const ValueKey('availability-switch'),
                      value: widget.availability == true,
                      onChanged: widget.onAvailabilityChanged == null
                          ? null
                          : (value) {
                              AppHaptics.light();
                              widget.onAvailabilityChanged!(value);
                            },
                    ),
                    Text(
                      widget.availability == true
                          ? 'Đang nhận việc'
                          : widget.availability == false
                          ? 'Tạm ngưng'
                          : 'Đang đồng bộ',
                      style: TextStyle(fontSize: 10, color: palette.muted),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
