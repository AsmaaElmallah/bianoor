import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

/// Inflated clay panel — tappable version has press-sink animation.
class TactileClayCard extends StatefulWidget {
  const TactileClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  State<TactileClayCard> createState() => _TactileClayCardState();
}

class _TactileClayCardState extends State<TactileClayCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _pressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final r = widget.borderRadius ?? AppRadius.brXl;
    final bg = widget.color ?? AppColors.surfaceContainerLowest;
    final tappable = widget.onTap != null;

    final body = AnimatedContainer(
      duration: _pressed
          ? const Duration(milliseconds: 85)
          : const Duration(milliseconds: 200),
      curve: _pressed ? Curves.easeIn : Curves.elasticOut,
      margin: widget.margin,
      padding: widget.padding,
      transform: tappable
          ? (Matrix4.identity()
            ..translate(0.0, _pressed ? 3.0 : 0.0)
            ..scale(_pressed ? 0.97 : 1.0))
          : null,
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: r,
        border: Border.all(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
          width: 3,
        ),
        boxShadow: _pressed ? AppShadows.soft : AppShadows.clayLift,
      ),
      child: widget.child,
    );

    if (!tappable) return body;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: body,
    );
  }
}
