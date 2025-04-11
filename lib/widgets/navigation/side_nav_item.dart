// lib/widgets/navigation/side_nav_item.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SideNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SideNavItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<SideNavItem> createState() => _SideNavItemState();
}

class _SideNavItemState extends State<SideNavItem>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!mounted || _controller == null) return;
    setState(() {
      _isHovered = isHovered;
      if (isHovered) {
        _controller!.forward();
      } else {
        _controller!.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    if (_controller == null || _scaleAnimation == null) {
      _initializeAnimation();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: AnimatedBuilder(
          animation: _controller!,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation?.value ?? 1.0,
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.isSelected
                          ? colorScheme.primaryContainer.withOpacity(
                            brightness == Brightness.dark ? 0.3 : 0.5,
                          )
                          : _isHovered
                          ? colorScheme.surfaceVariant.withOpacity(0.2)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color:
                          widget.isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight:
                            widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                        color:
                            widget.isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
