// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme(Color colorSeed) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorSeed,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ),
      scaffoldBackgroundColor: Colors.grey[100],
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Color.fromRGBO(255, 255, 255, 0.9), // Заменяем withOpacity(0.9)
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.grey[800],
      ),
      shadowColor: Color.fromRGBO(0, 0, 0, 0.2), // Заменяем withOpacity(0.2)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(
              colorSeed.red, colorSeed.green, colorSeed.blue, 0.8), // Заменяем withOpacity(0.8)
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}