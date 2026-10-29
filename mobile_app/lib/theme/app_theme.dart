import 'package:flutter/material.dart';

abstract final class AppTheme {
  static List<Color> brandGradient(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == workerOrange) {
      return const [Color(0xff7c2d12), Color(0xffc2410c)];
    }
    if (primary == contractorEmerald) {
      return const [Color(0xff064e3b), Color(0xff047857)];
    }
    return const [Color(0xff0f172a), Color(0xff1d4ed8)];
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
        : const Color(0xff1d4ed8);
    final background = worker
        ? const Color(0xfffff7ed)
        : contractor
        ? const Color(0xfff0fdf4)
        : const Color(0xfff1f5f9);
    final container = worker
        ? const Color(0xffffedd5)
        : contractor
        ? const Color(0xffd1fae5)
        : const Color(0xffdbeafe);
    final colors =
        ColorScheme.fromSeed(seedColor: accent, surface: Colors.white).copyWith(
          primary: accent,
          onPrimary: worker
              ? const Color(0xff1c0a00)
              : contractor
              ? const Color(0xff011b12)
              : Colors.white,
          primaryContainer: container,
          onPrimaryContainer: const Color(0xff0f172a),
          onSurface: const Color(0xff0f172a),
          onSurfaceVariant: const Color(0xff64748b),
        );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: const Color(0xff0f172a),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: Color(0xff0f172a),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140f172a),
        margin: const EdgeInsets.only(bottom: 16),
        shape: rounded,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffdce5e1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffdce5e1)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xffedf1ef),
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
      ),
    );
  }
}
