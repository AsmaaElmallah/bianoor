import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// "Pebble" progress indicator: a row of dots where the active one is
/// expanded into a pill shape.
class PebbleProgress extends StatelessWidget {
  const PebbleProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.surfaceContainerHighest,
    this.dotSize = 8,
    this.activeWidth = 28,
    this.spacing = 8,
  });

  final int totalSteps;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double activeWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: isActive ? activeWidth : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(dotSize),
          ),
        );
      }),
    );
  }
}
