// lib/main.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_navigation.dart';
import 'widgets/common/custom_title_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final themeMode =
      ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
  final accentColor = Color(prefs.getInt('accentColor') ?? Colors.indigo.value);

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp(initialThemeMode: themeMode, initialAccentColor: accentColor));
}

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

  void _handleThemeChange(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _handleColorChange(Color color) {
    setState(() {
      _accentColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathWorks',
      theme: AppTheme.lightTheme(_accentColor),
      darkTheme: AppTheme.darkTheme(_accentColor),
      themeMode: _themeMode,
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
