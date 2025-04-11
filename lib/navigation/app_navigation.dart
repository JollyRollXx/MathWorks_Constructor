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
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _screens[_selectedIndex],
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              isLargeScreen ? null : _buildBottomNavigationBar(),
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
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calculate,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'MathWorks',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
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
      unselectedItemColor: Theme.of(
        context,
      ).colorScheme.onSurface.withAlpha(153),
      backgroundColor: Theme.of(context).cardTheme.color,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
        BottomNavigationBarItem(
          icon: Icon(Icons.architecture),
          label: 'Конструктор',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        BottomNavigationBarItem(icon: Icon(Icons.info), label: 'О приложении'),
      ],
    );
  }
}
