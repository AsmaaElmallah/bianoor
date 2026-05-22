import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Inset clay track with glossy gradient fill.
class TactileClayProgress extends StatelessWidget {
  const TactileClayProgress({
    super.key,
    required this.value,
    this.height = 16,
  });

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppRadius.brFull,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            offset: const Offset(2, 2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            offset: const Offset(-1, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillW = constraints.maxWidth * v;
          return Stack(
            children: [
              if (fillW > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: fillW,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brFull,
                    gradient: const LinearGradient(
                      colors: [AppColors.tertiary, AppColors.primary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
