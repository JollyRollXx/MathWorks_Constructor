import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onPanStart: (details) {
        windowManager.startDragging();
      },
      child: Container(
        height: 32,
        color:
            brightness == Brightness.dark
                ? colorScheme.surface
                : colorScheme.surface,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              'MathWorks Constructor',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const Spacer(),
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
                          : colorScheme.surfaceVariant.withOpacity(0.3))
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
