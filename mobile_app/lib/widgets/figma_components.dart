import 'bouncing_button.dart';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared flat surfaces from the supplied 390px design references.
class FigmaCard extends StatelessWidget {
  const FigmaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppPalette.of(context).surface,
      border: Border.all(
        color: AppPalette.of(context).border,
        width: AppPalette.of(context).outdoor ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class KycBadge extends StatelessWidget {
  const KycBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: AppPalette.of(context).successSoft,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_outlined,
          size: 12,
          color: AppPalette.of(context).successStrong,
        ),
        const SizedBox(width: 3),
        Text(
          'Đã KYC',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppPalette.of(context).successStrong,
          ),
        ),
      ],
    ),
  );
}

class FigmaMetrics extends StatelessWidget {
  const FigmaMetrics({
    super.key,
    required this.values,
    this.accent = false,
    this.inverse = false,
  });
  final List<({String value, String label})> values;
  final bool accent;
  final bool inverse;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final metric in values)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    metric.value,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: inverse
                          ? Colors.white
                          : accent
                          ? Theme.of(context).colorScheme.primary
                          : AppPalette.of(context).ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: inverse
                        ? const Color(0xffcbd5e1)
                        : AppPalette.of(context).muted,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class RoleCards extends StatelessWidget {
  const RoleCards({super.key, required this.role, required this.onChanged});
  final String role;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final worker in [true, false]) ...[
        if (!worker) const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            worker: worker,
            selected: role == (worker ? 'ROLE_WORKER' : 'ROLE_CONTRACTOR'),
            onTap: onChanged == null
                ? null
                : () => onChanged!(worker ? 'ROLE_WORKER' : 'ROLE_CONTRACTOR'),
          ),
        ),
      ],
    ],
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.worker,
    required this.selected,
    required this.onTap,
  });
  final bool worker, selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = worker ? AppTheme.workerAmber : AppTheme.contractorBlue;
    return BouncingButton(
      enabled: onTap != null,
      child: Semantics(
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? color.withValues(alpha: palette.dark ? .18 : .06)
                : palette.surface,
            border: Border.all(
              color: selected ? color : palette.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: palette.outdoor
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap == null
                  ? null
                  : () {
                      AppHaptics.light();
                      onTap!();
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          worker
                              ? Icons.engineering_outlined
                              : Icons.apartment_outlined,
                          size: 28,
                          color: color,
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                          child: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            key: ValueKey(selected),
                            size: 22,
                            color: selected ? color : palette.border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      worker ? 'Tôi là thợ' : 'Tôi là chủ thầu',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      worker
                          ? 'Tìm việc, nhận tiền công'
                          : 'Tìm thợ giỏi, quản lý đội',
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
