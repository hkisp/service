import 'package:flutter/material.dart';

class IdcColors {
  static const bg = Color(0xFF0B1220);
  static const bgCard = Color(0xFF121A2B);
  static const cyan = Color(0xFF00D4FF);
  static const blue = Color(0xFF3B82F6);
  static const text = Color(0xFFE8EEF8);
  static const muted = Color(0xFF8B9BB4);
  static const danger = Color(0xFFEF4444);
  static const ok = Color(0xFF22C55E);
  static const warn = Color(0xFFF59E0B);
}

ThemeData buildIdcTheme({Brightness brightness = Brightness.dark}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: IdcColors.cyan,
    onPrimary: const Color(0xFF041018),
    secondary: IdcColors.blue,
    onSecondary: Colors.white,
    error: IdcColors.danger,
    onError: Colors.white,
    surface: isDark ? IdcColors.bgCard : const Color(0xFFF3F6FB),
    onSurface: isDark ? IdcColors.text : const Color(0xFF0B1220),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? IdcColors.bg : const Color(0xFFF7F9FC),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? IdcColors.bg : Colors.white,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark ? IdcColors.bgCard : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2F7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      hintStyle: TextStyle(color: IdcColors.muted),
    ),
  );
}
