// lib/widgets/navigation/side_nav_item.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SideNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SideNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  State<SideNavItem> createState() => _SideNavItemState();
}

class _SideNavItemState extends State<SideNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = widget.isSelected
        ? (_isHovered
        ? colorScheme.primary.withAlpha(38) // Заменяем withOpacity(0.15)
        : colorScheme.primary.withAlpha(25)) // Заменяем withOpacity(0.1)
        : (_isHovered
        ? colorScheme.primary.withAlpha(13) // Заменяем withOpacity(0.05)
        : Colors.transparent);

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : colorScheme.onSurface)
                    : _isHovered
                    ? colorScheme.primary.withAlpha(204) // Заменяем withOpacity(0.8)
                    : colorScheme.onSurface.withAlpha(178), // Заменяем withOpacity(0.7)
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isSelected
                        ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : colorScheme.onSurface)
                        : colorScheme.onSurface.withAlpha(230), // Заменяем withOpacity(0.9)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}