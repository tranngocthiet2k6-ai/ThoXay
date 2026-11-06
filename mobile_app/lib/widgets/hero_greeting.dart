import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import 'server_connection_notice.dart';
import 'tier_badge.dart';
import 'commercial_hero.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ServerConnectionNotice(api: widget.api),
        CommercialHero(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PresenceAvatar(
                    name: name,
                    online: worker ? widget.availability : null,
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
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xffcbd5e1),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          worker
                              ? (widget.title.contains('ứng tuyển')
                                    ? 'Việc của tôi'
                                    : 'Chào ${name.trim().split(" ").last}!')
                              : widget.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (worker) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_profile?.workerTier != null)
                      TierBadge(tier: _profile!.workerTier!),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xff475569)),
                      ),
                      padding: const EdgeInsets.only(left: 12, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.availability == true
                                  ? 'Đang nhận việc'
                                  : widget.availability == false
                                  ? 'Tạm ngưng nhận việc'
                                  : 'Đang đồng bộ trạng thái',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch(
                            key: const ValueKey('availability-switch'),
                            value: widget.availability == true,
                            onChanged: widget.onAvailabilityChanged,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
