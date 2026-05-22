import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Royal BeBo background — violet, amber, teal blobs on violet cream gradient.
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
        // Royal violet cream gradient base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAF5FF), // Violet-50
                Color(0xFFF3EEFF), // slightly deeper violet
              ],
            ),
          ),
        ),

        // Top-right — large violet blob
        Positioned(
          top: -55,
          right: -55,
          child: _Blob(
            diameter: 270,
            color: AppColors.primaryContainer.withValues(alpha: 0.65),
          ),
        ),

        // Top-left — amber gold blob
        Positioned(
          top: -20,
          left: -50,
          child: _Blob(
            diameter: 200,
            color: AppColors.secondaryContainer.withValues(alpha: 0.55),
          ),
        ),

        // Mid-left — deep violet accent
        Positioned(
          top: 180,
          left: -65,
          child: _Blob(
            diameter: 220,
            color: AppColors.primaryFixed.withValues(alpha: 0.40),
          ),
        ),

        // Mid-right — teal ocean blob
        Positioned(
          top: 300,
          right: -45,
          child: _Blob(
            diameter: 155,
            color: AppColors.tertiaryContainer.withValues(alpha: 0.55),
          ),
        ),

        // Lower-right — pink/rose accent (emotional track)
        Positioned(
          bottom: 170,
          right: -25,
          child: _Blob(
            diameter: 120,
            color: AppColors.trackEmotionalLight.withValues(alpha: 0.65),
          ),
        ),

        // Lower-left — amber glow
        Positioned(
          bottom: 220,
          left: -15,
          child: _Blob(
            diameter: 95,
            color: AppColors.secondaryFixed.withValues(alpha: 0.60),
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
                color: AppColors.primary.withValues(alpha: 0.06),
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
