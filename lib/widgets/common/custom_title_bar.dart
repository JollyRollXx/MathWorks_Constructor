import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    // Определяем цвет фона title bar в зависимости от темы
    final backgroundColor =
        brightness == Brightness.dark
            ? Color(
              0xFF242424,
            ) // Немного светлее чем darkSurface для темной темы
            : Colors.grey[50]; // Чуть темнее белого для светлой темы

    return GestureDetector(
      onPanStart: (details) {
        windowManager.startDragging();
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color:
                  brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey[300]!.withOpacity(0.5),
            ),
          ),
        ),
        child: Stack(
          children: [
            // Кнопки управления окном справа
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WindowButton(
                    icon: Icons.remove,
                    onPressed: () async {
                      await windowManager.minimize();
                    },
                    tooltip: 'Свернуть',
                  ),
                  _WindowButton(
                    icon: Icons.crop_square,
                    onPressed: () async {
                      if (await windowManager.isMaximized()) {
                        await windowManager.unmaximize();
                      } else {
                        await windowManager.maximize();
                      }
                    },
                    tooltip: 'Развернуть',
                  ),
                  _WindowButton(
                    icon: Icons.close,
                    isClose: true,
                    onPressed: () async {
                      await windowManager.close();
                    },
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
            ),
            // Название приложения по центру
            Center(
              child: Material(
                color: Colors.transparent,
                type: MaterialType.transparency,
                child: Text(
                  'MathWorks Constructor',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            child: Container(
              width: 46,
              height: double.infinity,
              color:
                  _isHovered
                      ? (widget.isClose
                          ? Colors.red.withOpacity(0.8)
                          : (brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05)))
                      : Colors.transparent,
              child: Icon(
                widget.icon,
                size: 16,
                color:
                    _isHovered && widget.isClose
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
