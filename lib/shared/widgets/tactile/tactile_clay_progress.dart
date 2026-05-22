import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Royal clay progress bar — animated liquid gradient fill (violet→amber).
class TactileClayProgress extends StatelessWidget {
  const TactileClayProgress({
    super.key,
    required this.value,
    this.height = 16,
    this.startColor,
    this.endColor,
  });

  final double value;
  final double height;
  final Color? startColor;
  final Color? endColor;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final start = startColor ?? AppColors.primary;       // violet
    final end   = endColor   ?? AppColors.secondary;    // amber gold

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppRadius.brFull,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
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
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  width: fillW,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brFull,
                    gradient: LinearGradient(
                      // Violet → Amber liquid gradient
                      colors: [start, end],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: start.withValues(alpha: 0.35),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Glossy shine highlight
                      Positioned(
                        top: 0,
                        left: 4,
                        right: 4,
                        child: Container(
                          height: height * 0.45,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: AppRadius.brFull,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Progress value dot at end
              if (fillW > height)
                Positioned(
                  right: constraints.maxWidth - fillW,
                  top: (height - height * 0.7) / 2,
                  child: Container(
                    width: height * 0.7,
                    height: height * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
