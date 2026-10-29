import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

enum NoticeKind { success, error, info }

class AppSnackBar extends SnackBar {
  AppSnackBar({
    super.key,
    required Widget content,
    NoticeKind kind = NoticeKind.success,
  }) : super(
         behavior: SnackBarBehavior.floating,
         showCloseIcon: true,
         backgroundColor: switch (kind) {
           NoticeKind.success => AppColors.successStrong,
           NoticeKind.error => AppColors.errorDeep,
           NoticeKind.info => AppColors.ink,
         },
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         content: Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Icon(switch (kind) {
               NoticeKind.success => Icons.check_circle_outline,
               NoticeKind.error => Icons.error_outline,
               NoticeKind.info => Icons.info_outline,
             }, color: Colors.white),
             const SizedBox(width: 12),
             Expanded(child: content),
           ],
         ),
       );
}
