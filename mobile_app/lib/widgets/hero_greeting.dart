import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'tier_badge.dart';
import 'design_motion.dart';

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
    final worker =
        widget.api.session?.role == 'ROLE_WORKER' ||
        widget.availability != null;
    return DesignReveal(
      child: DesignSurface(
        dark: true,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        name.isEmpty
                            ? 'TX'
                            : name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.ink,
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
                              color: AppColors.surface,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            worker
                                ? 'KHÔNG GIAN NGƯỜI THỢ'
                                : 'KHÔNG GIAN CHỦ THẦU',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DesignReveal(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 30,
                      height: 1.2,
                      letterSpacing: -.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DesignReveal(
                  child: Text(
                    widget.subtitle,
                    style: const TextStyle(color: Colors.white70, height: 1.6),
                  ),
                ),
                if (_profile?.role == 'ROLE_WORKER') ...[
                  const SizedBox(height: 16),
                  TierBadge(tier: _profile!.workerTier ?? 'SILVER'),
                ],
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (bounds.maxWidth >= 700)
                  Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 24),
                      const SizedBox(
                        width: 240,
                        child: ConstructionArtwork(height: 180),
                      ),
                    ],
                  )
                else
                  heading,
                if (worker) ...[
                  const SizedBox(height: 24),
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: SwitchListTile(
                      key: const ValueKey('availability-switch'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      secondary: Icon(
                        widget.availability == true
                            ? Icons.wifi_rounded
                            : Icons.pause_circle_outline,
                        color: widget.availability == true
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                      title: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: Text(
                          widget.availability == true
                              ? 'Đang nhận việc'
                              : widget.availability == false
                              ? 'Tạm ngưng nhận việc'
                              : 'Đang đồng bộ trạng thái',
                          key: ValueKey(widget.availability),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      value: widget.availability == true,
                      onChanged: widget.onAvailabilityChanged,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
