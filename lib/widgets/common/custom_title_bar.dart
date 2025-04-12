import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF000000) : Color(0xFFF5F5F5),
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Название приложения по центру
          Center(
            child: Text(
              'MathWorks Constructor',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Область для перетаскивания окна
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) => windowManager.startDragging(),
              child: const SizedBox.expand(),
            ),
          ),
          // Кнопки управления окном справа
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WindowButton(
                  icon: Icons.horizontal_rule,
                  onPressed: () async => await windowManager.minimize(),
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                _WindowButton(
                  icon: Icons.check_box_outline_blank,
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                  },
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                _WindowButton(
                  icon: Icons.clear,
                  onPressed: () async => await windowManager.close(),
                  colorScheme: colorScheme,
                  isDark: isDark,
                  isClose: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.colorScheme,
    required this.isDark,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: double.infinity,
          color: _getBackgroundColor(),
          child: Center(
            child: Icon(widget.icon, size: 16, color: _getIconColor()),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!_isHovered) return Colors.transparent;
    if (widget.isClose) {
      return widget.isDark ? Colors.red[800]! : Colors.red[500]!;
    }
    return widget.isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.08);
  }

  Color _getIconColor() {
    if (_isHovered && widget.isClose) {
      return Colors.white;
    }
    return widget.isDark ? Colors.white : Colors.black.withOpacity(0.8);
  }
}
