import 'package:flutter/material.dart';

class AppTheme {
  static const plum = Color(0xFF241D2B);
  static const surface = Color(0xFF382D40);
  static const lavender = Color(0xFFB9A0C9);
  static const cream = Color(0xFFF2EBDD);
  static const sage = Color(0xFFA8B8A0);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: lavender,
      brightness: Brightness.dark,
      surface: plum,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: plum,
      colorScheme: colorScheme.copyWith(
        primary: lavender,
        onPrimary: plum,
        surface: plum,
        onSurface: cream,
        secondary: sage,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: plum,
        foregroundColor: cream,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: lavender.withValues(alpha: 0.22),
        labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF71567D),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme.copyWith(
        primary: const Color(0xFF71567D),
        surface: const Color(0xFFFAF7F0),
        secondary: const Color(0xFF647C62),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAF7F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAF7F0),
        foregroundColor: Color(0xFF241D2B),
        centerTitle: false,
      ),
    );
  }
}
