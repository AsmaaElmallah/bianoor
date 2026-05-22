import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Clay-style selectable card — press sink + selection ring + haptic.
class SelectableCard extends StatefulWidget {
  const SelectableCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.iconBg = AppColors.primaryContainer,
    this.iconColor = AppColors.primary,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color iconBg;
  final Color iconColor;

  @override
  State<SelectableCard> createState() => _SelectableCardState();
}

class _SelectableCardState extends State<SelectableCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.selectionClick();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.isSelected;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 250),
        curve: _pressed ? Curves.easeIn : Curves.elasticOut,
        transform: Matrix4.identity()
          ..translate(0.0, _pressed ? 3.0 : 0.0)
          ..scale(_pressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Selected: tint of icon color. Unselected: clean white
          color: selected
              ? Color.lerp(AppColors.surfaceContainerLowest,
                  widget.iconColor, 0.07)
              : AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: selected
                ? widget.iconColor.withValues(alpha: 0.55)
                : AppColors.outline.withValues(alpha: 0.4),
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: _pressed
              ? []
              : selected
                  ? [
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFFC8906A).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selected ? 46 : 40,
              height: selected ? 46 : 40,
              decoration: BoxDecoration(
                color: selected
                    ? widget.iconColor.withValues(alpha: 0.18)
                    : widget.iconBg,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                color: selected ? widget.iconColor : widget.iconColor,
                size: selected ? 24 : 22,
                fill: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? widget.iconColor : AppColors.onSurface,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
