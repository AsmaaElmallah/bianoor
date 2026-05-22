import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Clay 3D primary CTA — gradient face, solid depth block, press-sink animation.
/// Matches the Bianur Clay design system (bottom shadow 6px, translateY on press).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconLeading = false,
    this.fullWidth = true,
    this.height = 58,
    this.gradient,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool iconLeading;
  final bool fullWidth;
  final double height;
  final Gradient? gradient;
  final Color? foregroundColor;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  static const _pressDuration = Duration(milliseconds: 100);
  static const _releaseDuration = Duration(milliseconds: 180);

  // Clay depth: 6px at rest, 2px when pressed
  double get _depth => _pressed ? 2.0 : 6.0;
  double get _translateY => _pressed ? 4.0 : 0.0;
  double get _scale => _pressed ? 0.97 : 1.0;

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = false);
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final fg = widget.foregroundColor ?? AppColors.onPrimary;
    final gradient = widget.gradient ?? AppColors.primaryGradient;

    // Depth block color = darker violet
    const depthColor = Color(0xFF4C1D95); // Violet-900

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        child: AnimatedContainer(
          duration: _pressed ? _pressDuration : _releaseDuration,
          curve: _pressed ? Curves.easeIn : Curves.elasticOut,
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height + _depth, // total height = button + depth block
          transform: Matrix4.identity()
            ..translate(0.0, _translateY)
            ..scale(_scale),
          transformAlignment: Alignment.center,
          child: Stack(
            children: [
              // ── Depth block (bottom shadow layer) ──────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: _pressed ? _pressDuration : _releaseDuration,
                  curve: Curves.easeOut,
                  height: widget.height + _depth,
                  decoration: BoxDecoration(
                    color: depthColor,
                    borderRadius: AppRadius.brLg,
                  ),
                ),
              ),

              // ── Glow behind button ─────────────────────────────────────
              if (!_pressed)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 0,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      borderRadius: AppRadius.brLg,
                    ),
                  ),
                ),

              // ── Face (gradient surface) ────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: AnimatedContainer(
                  duration: _pressed ? _pressDuration : _releaseDuration,
                  curve: Curves.easeOut,
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: AppRadius.brLg,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null && widget.iconLeading) ...[
                          Icon(widget.icon, color: fg, size: 22),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ),
                        if (widget.icon != null && !widget.iconLeading) ...[
                          const SizedBox(width: 8),
                          Icon(widget.icon, color: fg, size: 22),
                        ],
                      ],
                    ),
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
