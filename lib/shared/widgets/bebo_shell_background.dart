import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Warm pastel blob background — BeBo brand feel.
/// Larger, more visible blobs on a warm cream gradient base.
class BeboShellBackground extends StatelessWidget {
  const BeboShellBackground({
    super.key,
    this.showBottomCurve = true,
    this.bottomCurveHeight = 132,
  });

  final bool showBottomCurve;
  final double bottomCurveHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Warm gradient base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF8F2),
                Color(0xFFFFF0E4),
              ],
            ),
          ),
        ),

        // Top-right blob — lavender
        Positioned(
          top: -60,
          right: -50,
          child: _Blob(
            diameter: 260,
            color: AppColors.langFrenchBg.withValues(alpha: 0.55),
          ),
        ),

        // Top-left blob — mint teal
        Positioned(
          top: -30,
          left: -60,
          child: _Blob(
            diameter: 200,
            color: AppColors.primaryContainer.withValues(alpha: 0.6),
          ),
        ),

        // Mid-left blob — warm peach
        Positioned(
          top: 160,
          left: -70,
          child: _Blob(
            diameter: 220,
            color: AppColors.secondaryContainer.withValues(alpha: 0.55),
          ),
        ),

        // Mid-right blob — sky blue
        Positioned(
          top: 280,
          right: -50,
          child: _Blob(
            diameter: 160,
            color: AppColors.tertiaryContainer.withValues(alpha: 0.5),
          ),
        ),

        // Bottom-right accent — coral
        Positioned(
          bottom: 160,
          right: -30,
          child: _Blob(
            diameter: 130,
            color: AppColors.trackEmotionalLight.withValues(alpha: 0.65),
          ),
        ),

        // Bottom-left accent — mint
        Positioned(
          bottom: 200,
          left: -20,
          child: _Blob(
            diameter: 100,
            color: AppColors.trackExerciseLight.withValues(alpha: 0.7),
          ),
        ),

        if (showBottomCurve)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomCurveHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(44),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
