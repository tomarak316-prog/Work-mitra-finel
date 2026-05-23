// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const green      = Color(0xFF16a34a);
  static const greenLight = Color(0xFF22c55e);
  static const greenDark  = Color(0xFF15803d);
  static const greenPale  = Color(0xFFdcfce7);
  static const amber      = Color(0xFFf59e0b);
  static const red        = Color(0xFFef4444);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: green, brightness: Brightness.light),
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFFf0fdf4),
    appBarTheme: const AppBarTheme(
      backgroundColor: green,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFf9fafb),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFe5e7eb))),
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: green, brightness: Brightness.dark),
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFF0f172a),
  );
}
