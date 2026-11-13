import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xfff8fafc);
  static const surface = Color(0xffffffff);
  static const ink = Color(0xff0f172a);
  static const muted = Color(0xff64748b);
  static const border = Color(0xffe2e8f0);
  static const soft = Color(0xfff8fafc);
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

/// Semantic surfaces and readable status colors for all supported display modes.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({this.brightness = Brightness.light, this.outdoor = false});
  final Brightness brightness;
  final bool outdoor;
  bool get dark => brightness == Brightness.dark;
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? const AppPalette();
  Color tone(Color light, Color night, [Color? sun]) => outdoor
      ? sun ?? light
      : dark
      ? night
      : light;
  Color get canvas =>
      tone(AppColors.canvas, const Color(0xff0b1120), Colors.white);
  Color get surface =>
      tone(AppColors.surface, const Color(0xff172033), Colors.white);
  Color get ink => tone(AppColors.ink, const Color(0xfff8fafc), Colors.black);
  Color get muted =>
      tone(AppColors.muted, const Color(0xffb5c2d6), const Color(0xff262626));
  Color get border =>
      tone(AppColors.border, const Color(0xff475569), const Color(0xff182230));
  Color get soft => tone(AppColors.soft, const Color(0xff253147), Colors.white);
  Color get success => tone(AppColors.success, const Color(0xff86efac));
  Color get successStrong =>
      tone(AppColors.successStrong, const Color(0xff6ee7b7));
  Color get successSoft => tone(AppColors.successSoft, const Color(0xff103c32));
  Color get warning => tone(AppColors.warning, const Color(0xfffcd34d));
  Color get warningSoft => tone(AppColors.warningSoft, const Color(0xff483414));
  Color get warningPale => tone(AppColors.warningPale, const Color(0xff392d19));
  Color get error => tone(AppColors.error, const Color(0xfffca5a5));
  Color get errorStrong => tone(AppColors.errorStrong, const Color(0xfffca5a5));
  Color get errorSoft => tone(AppColors.errorSoft, const Color(0xff481f2a));
  Color get blue => tone(AppColors.blue, const Color(0xff93c5fd));
  Color get purple => tone(AppColors.purple, const Color(0xffc4b5fd));
  Color get sky => tone(AppColors.sky, const Color(0xff7dd3fc));
  Color get goldInk => tone(AppColors.goldInk, const Color(0xfffcd34d));
  Color get goldSoft => tone(AppColors.goldSoft, const Color(0xff493919));
  Color get goldTier => tone(AppColors.goldTier, const Color(0xfffcd34d));
  Color get slateLight => tone(AppColors.slateLight, const Color(0xff253147));
  Color get slateBorder => border;
  Color get skeleton => tone(
    AppColors.skeleton,
    const Color(0xff43536d),
    const Color(0xffb1b1b1),
  );
  Color get chartBlue => tone(AppColors.chartBlue, const Color(0xff93c5fd));
  Color get chartGold => tone(AppColors.chartGold, const Color(0xfffcd34d));
  Color get silverInk => tone(AppColors.silverInk, const Color(0xffcbd5e1));
  @override
  AppPalette copyWith({Brightness? brightness, bool? outdoor}) => AppPalette(
    brightness: brightness ?? this.brightness,
    outdoor: outdoor ?? this.outdoor,
  );
  @override
  AppPalette lerp(covariant AppPalette? other, double t) =>
      other == null || t < .5 ? this : other;
}

abstract final class AppTheme {
  static Color brandInk(BuildContext context) {
    final palette = AppPalette.of(context);
    if (palette.outdoor) return palette.ink;
    final blue = Theme.of(context).colorScheme.primary == contractorBlue;
    return palette.dark
        ? blue
              ? const Color(0xff93c5fd)
              : const Color(0xfffbbf24)
        : blue
        ? contractorBlue
        : const Color(0xff92400e);
  }

  static List<Color> brandGradient(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == workerAmber) {
      return const [AppColors.ink, Color(0xff413025)];
    }
    if (primary == contractorBlue) {
      return const [AppColors.ink, Color(0xff1e3a5f)];
    }
    return const [AppColors.ink, Color(0xff293c52)];
  }

  static const workerAmber = Color(0xffd97706);
  static const contractorBlue = Color(0xff1d4ed8);
  // Keep source compatibility for clients of the earlier theme names.
  static const workerOrange = workerAmber;
  static const contractorEmerald = contractorBlue;
  static ThemeData get light => forRole(null);
  static ThemeData forRole(
    String? role, {
    Brightness brightness = Brightness.light,
    bool outdoor = false,
  }) {
    brightness = outdoor ? Brightness.light : brightness;
    final palette = AppPalette(brightness: brightness, outdoor: outdoor);
    final worker = role == 'ROLE_WORKER';
    final contractor = role == 'ROLE_CONTRACTOR';
    final accent = worker
        ? workerAmber
        : contractor
        ? contractorBlue
        : role == null
        ? workerAmber
        : const Color(0xff1d4ed8);
    final background = palette.canvas;
    final container = brightness == Brightness.dark
        ? (worker
              ? const Color(0xff493014)
              : contractor
              ? const Color(0xff172e61)
              : const Color(0xff1e3a5f))
        : worker
        ? const Color(0xfffff7e6)
        : contractor
        ? const Color(0xffeff6ff)
        : const Color(0xffdbeafe);
    final colors =
        ColorScheme.fromSeed(
          seedColor: accent,
          surface: palette.surface,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: worker || role == null
              ? const Color(0xff1c0a00)
              : contractor
              ? Colors.white
              : Colors.white,
          primaryContainer: container,
          onPrimaryContainer: palette.ink,
          onSurface: palette.ink,
          onSurfaceVariant: palette.muted,
          outline: palette.border,
          error: palette.error,
        );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: palette.border, width: outdoor ? 2 : 1),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [palette],
      fontFamily: 'PlusJakartaSans',
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        headlineSmall: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
          height: 1.2,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: outdoor ? 16 : 14, height: 1.5),
      ).apply(bodyColor: palette.ink, displayColor: palette.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 20,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: palette.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: outdoor ? 0 : 1,
        shadowColor: const Color(0x100f172a),
        margin: const EdgeInsets.only(bottom: 16),
        shape: rounded,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.soft,
        constraints: const BoxConstraints(minHeight: 52),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.focused) ? accent : palette.muted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border, width: outdoor ? 2 : 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: outdoor ? palette.border : Colors.transparent,
            width: outdoor ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        floatingLabelStyle: TextStyle(
          color: outdoor ? palette.ink : accent,
          fontWeight: FontWeight.w700,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: outdoor
              ? palette.ink
              : brightness == Brightness.dark
              ? accent
              : worker || role == null
              ? const Color(0xff92400e)
              : contractor
              ? const Color(0xff1e40af)
              : accent,
          minimumSize: const Size(48, 48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black26,
          minimumSize: const Size(48, 48),
          backgroundColor: outdoor
              ? Colors.black
              : brightness == Brightness.dark
              ? null
              : worker || role == null
              ? workerAmber
              : contractor
              ? contractorBlue
              : accent,
          foregroundColor: outdoor
              ? Colors.white
              : worker || role == null
              ? const Color(0xff241400)
              : Colors.white,
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
          minimumSize: const Size(48, 48),
          foregroundColor: outdoor
              ? palette.ink
              : brightness == Brightness.dark
              ? accent
              : worker || role == null
              ? const Color(0xff92400e)
              : contractor
              ? const Color(0xff1e40af)
              : accent,
          side: BorderSide(
            color: outdoor ? palette.ink : palette.border,
            width: outdoor ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: accent.withValues(alpha: outdoor ? .20 : .12),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: palette.muted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        selectedColor: container,
        side: BorderSide(color: palette.border, width: outdoor ? 2 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        checkmarkColor: palette.ink,
        secondaryLabelStyle: TextStyle(
          color: palette.ink,
          fontWeight: FontWeight.w700,
        ),
        labelStyle: TextStyle(
          color: palette.ink,
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: palette.muted,
        indicatorColor: accent,
        dividerColor: palette.border,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: palette.ink,
        ),
      ),
    );
  }
}
