import 'package:flutter/material.dart';

class GlukColors {
  static const Color bg = Color(0xFFEFEDE3);
  static const Color surface = Color(0xFFF7F6F0);
  static const Color ink = Color(0xFF302F2C);
  static const Color muted = Color(0xFF85847C);
  static const Color accent = Color(0xFFD19D75);
  static const Color accentSoft = Color(0xFFE9DED0);
  static const Color darkBg = Color(0xFF171816);
  static const Color darkSurface = Color(0xFF20221F);
  static const Color darkInk = Color(0xFFF0EDE4);
  static const Color darkMuted = Color(0xFFA6A59D);
}

class GlukTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? GlukColors.darkBg : const Color(0xFFEFEDE3);
    final surface = isDark ? GlukColors.darkSurface : GlukColors.surface;
    final ink = isDark ? GlukColors.darkInk : GlukColors.ink;
    final muted = isDark ? GlukColors.darkMuted : GlukColors.muted;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: bg,
      secondary: GlukColors.accent,
      onSecondary: GlukColors.ink,
      error: const Color(0xFFB85E52),
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink).copyWith(
            displayLarge: TextStyle(fontSize: 48, height: 1.02, letterSpacing: -2.2, fontWeight: FontWeight.w800, color: ink),
            displayMedium: TextStyle(fontSize: 40, height: 1.04, letterSpacing: -1.8, fontWeight: FontWeight.w800, color: ink),
            headlineLarge: TextStyle(fontSize: 30, height: 1.08, letterSpacing: -1.1, fontWeight: FontWeight.w800, color: ink),
            headlineMedium: TextStyle(fontSize: 24, height: 1.08, letterSpacing: -0.7, fontWeight: FontWeight.w800, color: ink),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink),
            titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
            bodyLarge: TextStyle(fontSize: 14, height: 1.5, color: ink),
            bodyMedium: TextStyle(fontSize: 13, height: 1.5, color: ink),
            bodySmall: TextStyle(fontSize: 11, height: 1.4, color: muted),
            labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ink),
            labelSmall: TextStyle(fontSize: 9, letterSpacing: 1.25, fontWeight: FontWeight.w800, color: muted),
          ),
      dividerColor: ink.withValues(alpha: isDark ? 0.12 : 0.09),
      cardColor: surface,
      iconTheme: IconThemeData(color: muted, size: 20),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(alpha: 0.7),
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: ink.withValues(alpha: 0.07))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: GlukColors.accent, width: 1.3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: GlukColors.accent,
        inactiveTrackColor: ink.withValues(alpha: 0.10),
        thumbColor: ink,
        overlayColor: GlukColors.accent.withValues(alpha: 0.14),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? bg : muted),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? ink : ink.withValues(alpha: 0.16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: bg, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
