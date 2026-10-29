import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xfff7f8fa);
  static const surface = Color(0xffffffff);
  static const ink = Color(0xff182230);
  static const muted = Color(0xff64748b);
  static const border = Color(0xffe4e7ec);
  static const soft = Color(0xfff2f4f7);
  static const success = Color(0xff15803d);
  static const warning = Color(0xffb45309);
  static const error = Color(0xffb42318);
  static const gold = Color(0xfffbbf24);
  static const successStrong = Color(0xff047857);
  static const successSoft = Color(0xffecfdf5);
  static const warningSoft = Color(0xfffff1d8);
  static const warningPale = Color(0xfffffbeb);
  static const errorSoft = Color(0xfffef2f2);
  static const errorStrong = Color(0xffb91c1c);
  static const errorDeep = Color(0xff991b1b);
  static const sky = Color(0xff0284c7);
  static const skySoft = Color(0xff93c5fd);
  static const goldInk = Color(0xffa16207);
  static const goldSoft = Color(0xfffef3c7);
  static const sand = Color(0xffffdf9e);
  static const blue = Color(0xff1d4ed8);
  static const purple = Color(0xff6d28d9);
  static const slateLight = Color(0xfff1f5f9);
  static const slateBorder = Color(0xffcbd5e1);
  static const skeleton = Color(0xffdfe7e2);
  static const transparentWhite = Color(0x00ffffff);
  static const whiteMuted = Color(0xb3ffffff);
  static const chartBlue = Color(0xff31699e);
  static const chartGold = Color(0xff8d6216);
  static const silverInk = Color(0xff5f717b);
  static const goldTier = Color(0xffaa771c);
}

abstract final class AppTheme {
  static List<Color> brandGradient(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == workerOrange) {
      return const [AppColors.ink, Color(0xff413025)];
    }
    if (primary == contractorEmerald) {
      return const [AppColors.ink, Color(0xff133e36)];
    }
    return const [AppColors.ink, Color(0xff293c52)];
  }

  static const workerOrange = Color(0xffea580c);
  static const contractorEmerald = Color(0xff059669);
  static ThemeData get light => forRole(null);
  static ThemeData forRole(String? role) {
    final worker = role == 'ROLE_WORKER';
    final contractor = role == 'ROLE_CONTRACTOR';
    final accent = worker
        ? workerOrange
        : contractor
        ? contractorEmerald
        : role == null
        ? workerOrange
        : const Color(0xff1d4ed8);
    const background = AppColors.canvas;
    final container = worker
        ? const Color(0xffffedd5)
        : contractor
        ? const Color(0xffd1fae5)
        : const Color(0xffdbeafe);
    final colors =
        ColorScheme.fromSeed(seedColor: accent, surface: Colors.white).copyWith(
          primary: accent,
          onPrimary: worker || role == null
              ? const Color(0xff1c0a00)
              : contractor
              ? const Color(0xff011b12)
              : Colors.white,
          primaryContainer: container,
          onPrimaryContainer: const Color(0xff0f172a),
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.muted,
          outline: AppColors.border,
          error: AppColors.error,
        );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'PlusJakartaSans',
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        toolbarHeight: 72,
        titleSpacing: 24,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: AppColors.ink,
        margin: const EdgeInsets.only(bottom: 16),
        shape: rounded,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.soft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        floatingLabelStyle: TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: container,
        elevation: 0,
        height: 80,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: AppColors.muted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.soft,
        selectedColor: container,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: accent,
        dividerColor: AppColors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
