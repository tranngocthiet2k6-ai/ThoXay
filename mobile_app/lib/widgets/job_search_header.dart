import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

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
    elevation: 0,
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
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAdvanced != null)
                IconButton(
                  tooltip: 'Bộ lọc vị trí',
                  onPressed: onAdvanced,
                  icon: const Icon(Icons.tune),
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
                label: Text(type.isEmpty ? 'Tất cả' : type),
                selected: jobType == type,
                onSelected: enabled ? (_) => onType(type) : null,
              ),
              const SizedBox(width: 8),
            ],
            FilterChip(
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
