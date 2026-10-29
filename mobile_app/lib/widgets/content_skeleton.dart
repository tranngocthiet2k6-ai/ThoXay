import 'package:flutter/material.dart';

import 'loading_jobs.dart';

class ContentSkeleton extends StatelessWidget {
  const ContentSkeleton({
    super.key,
    this.label = 'Đang tải nội dung',
    this.compact = false,
    this.chat = false,
  });
  final String label;
  final bool compact, chat;
  @override
  Widget build(BuildContext context) => ShimmerSurface(
    label: label,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < (compact ? 1 : 3); i++)
            Align(
              alignment: chat && i.isEven
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: chat ? .72 : 1,
                child: const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: .6,
                          child: SkeletonLine(height: 20),
                        ),
                        SizedBox(height: 16),
                        SkeletonLine(),
                        SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: .8,
                          child: SkeletonLine(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
