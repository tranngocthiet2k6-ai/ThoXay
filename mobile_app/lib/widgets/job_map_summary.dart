import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Scroll the parent page, never the map's camera, to the jobs below it.
void revealMapJobList(
  GlobalKey mapKey,
  GlobalKey listKey, {
  double pinnedHeaderHeight = 0,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final target = listKey.currentContext ?? mapKey.currentContext;
    final box = target?.findRenderObject();
    if (target == null || box is! RenderBox || !box.attached || !box.hasSize) {
      return;
    }
    final viewport = RenderAbstractViewport.maybeOf(box);
    final position = Scrollable.maybeOf(target)?.position;
    if (viewport == null || position == null || !position.hasContentDimensions) {
      return;
    }
    final listIsMounted = listKey.currentContext != null;
    final offset =
        viewport.getOffsetToReveal(box, 0).offset +
        (listIsMounted ? 0 : box.size.height + 16) -
        pinnedHeaderHeight;
    final destination = offset
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (MediaQuery.disableAnimationsOf(target)) {
      position.jumpTo(destination);
    } else {
      unawaited(
        position.animateTo(
          destination,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  });
}

Future<void> showJobMapSummary(
  BuildContext context, {
  required Job job,
  required VoidCallback onDetails,
  required VoidCallback onCloseMap,
  required String primaryLabel,
  VoidCallback? onPrimary,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (sheetContext) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * .8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Công trình trên bản đồ',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng thẻ công trình',
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(job.title, style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '${money(job.salaryPerDay)}/ngày',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandInk(sheetContext),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${job.jobType} · ${job.address}',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${statusLabel(job.status)}${job.distanceKm == null ? "" : " · ${job.distanceKm!.toStringAsFixed(1)} km"}',
            ),
            const SizedBox(height: 8),
            Text(
              'Chủ thầu: ${job.contractorName}${job.contractorVerified ? " · Đã KYC" : ""}',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onDetails();
                    },
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimary == null
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            onPrimary();
                          },
                    child: Text(primaryLabel, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                onCloseMap();
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'Đóng / Xem danh sách công trình',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
