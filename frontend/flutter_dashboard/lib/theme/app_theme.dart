import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF1B4D3E);
  static const _secondary = Color(0xFF2E7D5A);
  static const _darkPrimary = Color(0xFF4ADE80);
  static const _darkSecondary = Color(0xFF2E7D5A);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        primary: _primary,
        secondary: _secondary,
        surface: const Color(0xFFF8FAF9),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F6F5),
      dividerColor: Colors.grey.shade200,
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: false,
      ),
      fontFamily: 'Segoe UI',
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _darkPrimary,
        brightness: Brightness.dark,
        primary: _darkPrimary,
        secondary: _darkSecondary,
        surface: const Color(0xFF1A2420),
      ),
      scaffoldBackgroundColor: const Color(0xFF121816),
      dividerColor: const Color(0xFF2A3530),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A2420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A2420),
        foregroundColor: Color(0xFFE8EDE9),
        elevation: 0,
        centerTitle: false,
      ),
      fontFamily: 'Segoe UI',
    );
  }
}
