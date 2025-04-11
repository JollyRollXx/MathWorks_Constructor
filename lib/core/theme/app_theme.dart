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
    final darkBackground = Color(
      0xFF1A1A1A,
    ); // Темнее чем стандартный grey[850]
    final darkSurface = Color(0xFF2C2C2C); // Темнее чем стандартный grey[800]

    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorSeed,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          headlineSmall: TextStyle(color: Colors.grey[200]),
          titleLarge: TextStyle(color: Colors.grey[200]),
          titleMedium: TextStyle(color: Colors.grey[300]),
          bodyLarge: TextStyle(color: Colors.grey[300]),
          bodyMedium: TextStyle(color: Colors.grey[400]),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: darkSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      shadowColor: Colors.black.withOpacity(0.3),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorSeed.withOpacity(0.8),
          foregroundColor: Colors.white,
        ),
      ),
      dialogBackgroundColor: darkSurface,
      popupMenuTheme: PopupMenuThemeData(color: darkSurface),
      dividerColor: Colors.grey[700],
    );
  }
}
