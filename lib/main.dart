// lib/main.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    title: 'MathWorks Constructor',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Color _colorSeed = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
      _colorSeed = Color(prefs.getInt('accentColor') ?? Colors.indigo.toARGB32());
    });
  }

  void _updateTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  void _updateColor(Color color) async {
    setState(() => _colorSeed = color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentColor', color.toARGB32()); // Заменяем value
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathWorks Constructor',
      theme: AppTheme.lightTheme(_colorSeed),
      darkTheme: AppTheme.darkTheme(_colorSeed),
      themeMode: _themeMode,
      home: NavigationExample(
        onThemeChanged: _updateTheme,
        onColorChanged: _updateColor,
      ),
    );
  }
}