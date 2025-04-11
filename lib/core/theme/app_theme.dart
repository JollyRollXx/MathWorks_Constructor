// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme(Color colorSeed) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorSeed,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      scaffoldBackgroundColor: Colors.grey[100],
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withOpacity(0.9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData darkTheme(Color colorSeed) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorSeed,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[850],
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          headlineSmall: TextStyle(color: Colors.grey[300]),
          titleLarge: TextStyle(color: Colors.grey[300]),
          titleMedium: TextStyle(color: Colors.grey[400]),
          bodyLarge: TextStyle(color: Colors.grey[400]),
          bodyMedium: TextStyle(color: Colors.grey[500]),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey[800],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      shadowColor: Colors.black.withOpacity(0.2),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorSeed.withOpacity(0.8),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
