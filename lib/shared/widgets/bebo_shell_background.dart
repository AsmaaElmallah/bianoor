import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Soft pastel blobs + optional bottom curve (BeBo-style shell).
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
        Positioned(
          top: -72,
          right: -48,
          child: _Blob(
            diameter: 220,
            color: AppColors.langFrenchBg.withValues(alpha: 0.75),
          ),
        ),
        Positioned(
          top: 96,
          left: -56,
          child: _Blob(
            diameter: 180,
            color: AppColors.secondaryContainer.withValues(alpha: 0.9),
          ),
        ),
        Positioned(
          bottom: 140,
          right: -24,
          child: _Blob(
            diameter: 100,
            color: AppColors.langEnglishBg.withValues(alpha: 0.55),
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
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
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
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
