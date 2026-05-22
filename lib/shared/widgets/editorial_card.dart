import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

/// Card with a soft colored side strip on the start (RTL: right) edge.
/// Used for rules, info cards, and section highlights.
class EditorialCard extends StatelessWidget {
  const EditorialCard({
    super.key,
    required this.child,
    this.accentColor = AppColors.primary,
    this.background = AppColors.surfaceContainerLowest,
    this.padding = const EdgeInsets.all(14),
    this.stripWidth = 6,
  });

  final Widget child;
  final Color accentColor;
  final Color background;
  final EdgeInsets padding;
  final double stripWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Subtle warm tint from accent color
        color: Color.lerp(background, accentColor, 0.04),
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Accent strip — more visible (was 0.25, now 0.55)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: stripWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withValues(alpha: 0.75),
                    accentColor.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
