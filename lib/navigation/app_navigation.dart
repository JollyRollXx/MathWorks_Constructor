// lib/navigation/app_navigation.dart
import 'package:flutter/material.dart';
import '/screens/home_screen.dart';
import '/screens/constructor_screen.dart';
import '/screens/settings_screen.dart';
import '../widgets/navigation/side_nav_item.dart';
import 'package:google_fonts/google_fonts.dart';
import '/screens/about_screen.dart';

class NavigationExample extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  final void Function(Color) onColorChanged;

  const NavigationExample({
    super.key,
    required this.onThemeChanged,
    required this.onColorChanged,
  });

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const ConstructorScreen(),
      SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        onColorChanged: widget.onColorChanged,
      ),
      const AboutScreen(), // Добавляем новый экран
    ];
  }

  void _updateIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;

        return Scaffold(
          body: Row(
            children: [
              if (isLargeScreen) _buildSideNavigationBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _screens[_selectedIndex],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isLargeScreen ? null : _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildSideNavigationBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'MathWorks',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                SideNavItem(
                  icon: Icons.home,
                  label: 'Главная',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _updateIndex(0),
                ),
                SideNavItem(
                  icon: Icons.architecture,
                  label: 'Конструктор',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _updateIndex(1),
                ),
                const Divider(height: 32),
                SideNavItem(
                  icon: Icons.settings,
                  label: 'Настройки',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _updateIndex(2),
                ),
                SideNavItem(
                  icon: Icons.info,
                  label: 'О приложении',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _updateIndex(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _updateIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface.withAlpha(153),
      backgroundColor: Theme.of(context).cardTheme.color,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Главная',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.architecture),
          label: 'Конструктор',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Настройки',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info),
          label: 'О приложении',
        ),
      ],
    );
  }
}