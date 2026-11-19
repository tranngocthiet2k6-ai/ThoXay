import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

import 'figma_design.dart';

class JobSearchHeader extends SliverPersistentHeaderDelegate {
  JobSearchHeader({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    elevation: overlapsContent ? 3 : 0,
    shadowColor: const Color(0x100F172A),
    shape: Border(
      bottom: BorderSide(
        color: overlapsContent
            ? AppPalette.of(context).border
            : Colors.transparent,
      ),
    ),
    child: child,
  );
  @override
  bool shouldRebuild(covariant JobSearchHeader oldDelegate) => true;
}

class JobSearchFilters extends StatelessWidget {
  const JobSearchFilters({
    super.key,
    required this.controller,
    required this.jobType,
    required this.salaryFirst,
    required this.enabled,
    required this.onSearch,
    required this.onType,
    required this.onSalary,
    this.onAdvanced,
  });
  final TextEditingController controller;
  final String jobType;
  final bool salaryFirst, enabled;
  final ValueChanged<String> onSearch, onType;
  final ValueChanged<bool> onSalary;
  final VoidCallback? onAdvanced;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: controller,
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Tìm tên công trình, địa điểm…',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          hintStyle: TextStyle(
            fontSize: 12,
            color: AppPalette.of(context).muted,
          ),
          prefixIcon: const Center(
            widthFactor: 1,
            heightFactor: 1,
            child: FigmaIcon('7237e', size: 20),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAdvanced != null)
                IconButton(
                  tooltip: 'Bộ lọc vị trí',
                  onPressed: onAdvanced,
                  icon: const FigmaIcon('d2b73', size: 20),
                ),
              if (controller.text.isNotEmpty)
                IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onSearch('');
                  },
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final type in ['', 'Thợ chính', 'Phụ hồ']) ...[
              ChoiceChip(
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: jobType == type
                      ? AppTheme.brandInk(context)
                      : AppPalette.of(context).ink,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(type.isEmpty ? 'Tất cả' : type),
                selected: jobType == type,
                onSelected: enabled ? (_) => onType(type) : null,
              ),
              const SizedBox(width: 8),
            ],
            FilterChip(
              labelStyle: TextStyle(
                fontSize: 11,
                color: AppPalette.of(context).ink,
              ),
              label: const Text('Lương cao nhất'),
              avatar: const Icon(Icons.sort, size: 18),
              selected: salaryFirst,
              onSelected: enabled ? onSalary : null,
            ),
          ],
        ),
      ),
    ],
  );
}
