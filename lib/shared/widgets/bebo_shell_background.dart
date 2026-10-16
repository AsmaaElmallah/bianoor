import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Arena phone shell — flat cream #FFF9F3 (no decorative blobs).
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
    return const ColoredBox(color: AppColors.background);
  }
}
