// lib/main.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_navigation.dart';
import 'widgets/common/custom_title_bar.dart';

/// Константы приложения
class AppConstants {
  static const String appTitle = 'MathWorks';
  static const Size defaultWindowSize = Size(1200, 800);
  static const Size minimumWindowSize = Size(800, 600);

  // Ключи для SharedPreferences
  static const String themeModeKey = 'themeMode';
  static const String accentColorKey = 'accentColor';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Инициализация настроек
  final prefs = await SharedPreferences.getInstance();
  final themeMode =
      ThemeMode.values[prefs.getInt(AppConstants.themeModeKey) ??
          ThemeMode.system.index];
  final accentColor = Color(
    prefs.getInt(AppConstants.accentColorKey) ?? Colors.indigo.value,
  );

  WindowOptions windowOptions = const WindowOptions(
    size: AppConstants.defaultWindowSize,
    minimumSize: AppConstants.minimumWindowSize,
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp(initialThemeMode: themeMode, initialAccentColor: accentColor));
}

/// Основной виджет приложения
class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final Color initialAccentColor;

  const MyApp({
    Key? key,
    required this.initialThemeMode,
    required this.initialAccentColor,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late Color _accentColor;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _accentColor = widget.initialAccentColor;
  }

  // Сохраняем настройки при изменении темы
  Future<void> _handleThemeChange(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.themeModeKey, mode.index);
    setState(() {
      _themeMode = mode;
    });
  }

  // Сохраняем настройки при изменении цвета
  Future<void> _handleColorChange(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.accentColorKey, color.value);
    setState(() {
      _accentColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme(_accentColor),
      darkTheme: AppTheme.darkTheme(_accentColor),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false, // Убираем баннер debug
      home: Column(
        children: [
          const CustomTitleBar(),
          Expanded(
            child: NavigationExample(
              onThemeChanged: _handleThemeChange,
              onColorChanged: _handleColorChange,
            ),
          ),
        ],
      ),
    );
  }
}
