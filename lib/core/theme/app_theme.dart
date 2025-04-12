// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const String _colorSchemeKey = 'color_scheme';
  static const String _defaultScheme = 'default';
  static const String _monochromeScheme = 'monochrome';
  static const Color primaryColor = Color(0xFF2196F3);
  static const String _themeModeKey = 'theme_mode';

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString(_themeModeKey);
    if (themeMode == null) {
      await prefs.setString(_themeModeKey, 'system');
      return ThemeMode.system;
    }
    return ThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'ThemeMode.$themeMode',
      orElse: () => ThemeMode.system,
    );
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.toString().split('.').last);
  }

  static Future<String> getColorScheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_colorSchemeKey) ?? 'default';
  }

  static Future<void> setColorScheme(String scheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, scheme);
  }

  static ThemeData lightTheme(Color colorSeed) {
    final bool isMonochrome = colorSeed == Colors.black;
    final colorScheme =
        isMonochrome
            ? ColorScheme.light(
              primary: colorSeed,
              onPrimary: Colors.white,
              primaryContainer: Color(0xFFF5F5F5),
              onPrimaryContainer: colorSeed,
              secondary: colorSeed,
              onSecondary: Colors.white,
              secondaryContainer: Color(0xFFF5F5F5),
              onSecondaryContainer: colorSeed,
              tertiary: colorSeed,
              onTertiary: Colors.white,
              tertiaryContainer: Color(0xFFF5F5F5),
              onTertiaryContainer: colorSeed,
              error: colorSeed,
              onError: Colors.white,
              errorContainer: Color(0xFFF5F5F5),
              onErrorContainer: colorSeed,
              background: Colors.white,
              onBackground: colorSeed,
              surface: Colors.white,
              onSurface: colorSeed,
              surfaceVariant: Color(0xFFF5F5F5),
              onSurfaceVariant: colorSeed,
              outline: Color(0xFFE0E0E0),
              outlineVariant: Color(0xFFF5F5F5),
              shadow: colorSeed.withOpacity(0.1),
              scrim: colorSeed,
              inverseSurface: colorSeed,
              onInverseSurface: Colors.white,
              inversePrimary: Colors.white,
              surfaceTint: Colors.transparent,
            )
            : ColorScheme.fromSeed(
              seedColor: colorSeed,
              brightness: Brightness.light,
            );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      scaffoldBackgroundColor: isMonochrome ? Colors.white : Colors.grey[100],
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: isMonochrome ? Color(0xFFE0E0E0) : null,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary, size: 24),
    );
  }

  static ThemeData darkTheme(Color colorSeed) {
    final bool isMonochrome = colorSeed == Colors.black;
    final darkBackground = Color(0xFF1A1A1A);
    final darkSurface = Color(0xFF2C2C2C);

    final colorScheme =
        isMonochrome
            ? ColorScheme.dark(
              primary: Colors.white,
              onPrimary: darkBackground,
              primaryContainer: Color(0xFF404040),
              onPrimaryContainer: Colors.white,
              secondary: Colors.white,
              onSecondary: darkBackground,
              secondaryContainer: Color(0xFF404040),
              onSecondaryContainer: Colors.white,
              tertiary: Colors.white,
              onTertiary: darkBackground,
              tertiaryContainer: Color(0xFF404040),
              onTertiaryContainer: Colors.white,
              error: Colors.white,
              onError: darkBackground,
              errorContainer: Color(0xFF404040),
              onErrorContainer: Colors.white,
              background: darkBackground,
              onBackground: Colors.white,
              surface: darkSurface,
              onSurface: Colors.white,
              surfaceVariant: Color(0xFF404040),
              onSurfaceVariant: Colors.white,
              outline: Color(0xFF666666),
              outlineVariant: Color(0xFF404040),
              shadow: Colors.black.withOpacity(0.2),
              scrim: Colors.white,
              inverseSurface: Colors.white,
              onInverseSurface: darkBackground,
              inversePrimary: darkBackground,
              surfaceTint: Colors.transparent,
            )
            : ColorScheme.fromSeed(
              seedColor: colorSeed,
              brightness: Brightness.dark,
            );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
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
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: isMonochrome ? Color(0xFF404040) : null,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary, size: 24),
      shadowColor: Colors.black.withOpacity(0.3),
      dialogBackgroundColor: darkSurface,
      popupMenuTheme: PopupMenuThemeData(color: darkSurface),
    );
  }

  static Future<ThemeData> getThemeWithColorScheme(
    Color colorSeed,
    Brightness brightness,
  ) async {
    final scheme = await getColorScheme();
    final baseTheme =
        brightness == Brightness.light
            ? lightTheme(colorSeed)
            : darkTheme(colorSeed);

    if (scheme == _monochromeScheme) {
      return baseTheme.copyWith(
        colorScheme:
            brightness == Brightness.light
                ? const ColorScheme.light(
                  primary: Colors.black,
                  onPrimary: Colors.white,
                  primaryContainer: Color(0xFFE0E0E0),
                  onPrimaryContainer: Colors.black,
                  secondary: Colors.black,
                  onSecondary: Colors.white,
                  secondaryContainer: Color(0xFFE0E0E0),
                  onSecondaryContainer: Colors.black,
                  tertiary: Colors.black,
                  onTertiary: Colors.white,
                  tertiaryContainer: Color(0xFFE0E0E0),
                  onTertiaryContainer: Colors.black,
                  error: Colors.black,
                  onError: Colors.white,
                  errorContainer: Color(0xFFE0E0E0),
                  onErrorContainer: Colors.black,
                  background: Colors.white,
                  onBackground: Colors.black,
                  surface: Colors.white,
                  onSurface: Colors.black,
                  surfaceVariant: Color(0xFFF5F5F5),
                  onSurfaceVariant: Colors.black,
                  outline: Colors.black,
                  outlineVariant: Color(0xFFE0E0E0),
                  shadow: Colors.black,
                  scrim: Colors.black,
                  inverseSurface: Colors.black,
                  onInverseSurface: Colors.white,
                  inversePrimary: Colors.white,
                  surfaceTint: Colors.black,
                )
                : const ColorScheme.dark(
                  primary: Colors.white,
                  onPrimary: Colors.black,
                  primaryContainer: Color(0xFF2C2C2C),
                  onPrimaryContainer: Colors.white,
                  secondary: Colors.white,
                  onSecondary: Colors.black,
                  secondaryContainer: Color(0xFF2C2C2C),
                  onSecondaryContainer: Colors.white,
                  tertiary: Colors.white,
                  onTertiary: Colors.black,
                  tertiaryContainer: Color(0xFF2C2C2C),
                  onTertiaryContainer: Colors.white,
                  error: Colors.white,
                  onError: Colors.black,
                  errorContainer: Color(0xFF2C2C2C),
                  onErrorContainer: Colors.white,
                  background: Color(0xFF1A1A1A),
                  onBackground: Colors.white,
                  surface: Color(0xFF1A1A1A),
                  onSurface: Colors.white,
                  surfaceVariant: Color(0xFF2C2C2C),
                  onSurfaceVariant: Colors.white,
                  outline: Colors.white,
                  outlineVariant: Color(0xFF2C2C2C),
                  shadow: Colors.white,
                  scrim: Colors.white,
                  inverseSurface: Colors.white,
                  onInverseSurface: Colors.black,
                  inversePrimary: Colors.black,
                  surfaceTint: Colors.white,
                ),
      );
    }

    return baseTheme;
  }
}
