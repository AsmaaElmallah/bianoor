import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';

/// Thick 3D clay button with bottom depth block (press sinks).
class TactileClayButton extends StatefulWidget {
  const TactileClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.onPrimary,
    this.depthColor,
    this.height = 56,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? depthColor;
  final double height;
  final bool fullWidth;

  @override
  State<TactileClayButton> createState() => _TactileClayButtonState();
}

class _TactileClayButtonState extends State<TactileClayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final depth = widget.depthColor ?? _darker(widget.backgroundColor, 0.22);
    final lift = _pressed ? 2.0 : 6.0;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height,
          transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            boxShadow: [
              BoxShadow(
                color: depth,
                offset: Offset(0, lift),
                blurRadius: 0,
              ),
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.25),
                offset: const Offset(0, 12),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: AppRadius.brLg,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                left: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.foregroundColor, size: 24),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: widget.foregroundColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _darker(Color c, double amount) {
    return Color.lerp(c, Colors.black, amount) ?? c;
  }
}
