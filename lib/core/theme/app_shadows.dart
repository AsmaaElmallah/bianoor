import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  /// Soft “clay” lift: faint top highlight + diffuse depth (no heavy blur).
  static List<BoxShadow> clayLift = [
    BoxShadow(
      color: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
      blurRadius: 0,
      offset: const Offset(-0.5, -1.5),
    ),
    BoxShadow(
      color: AppColors.onSurface.withValues(alpha: 0.07),
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.05),
      blurRadius: 28,
      spreadRadius: -10,
      offset: const Offset(0, 12),
    ),
  ];

  /// Primary CTA: clay depth + brand glow (stacked).
  static List<BoxShadow> get clayPrimaryButton => [
        ...clayLift,
        ...primaryGlow,
      ];

  static List<BoxShadow> editorial = [
    BoxShadow(
      color: AppColors.onSurface.withValues(alpha: 0.045),
      blurRadius: 26,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.onSurface.withValues(alpha: 0.03),
      blurRadius: 24,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.18),
      blurRadius: 24,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> bottomNav = [
    BoxShadow(
      color: AppColors.onSurface.withValues(alpha: 0.06),
      blurRadius: 32,
      offset: const Offset(0, -8),
    ),
  ];
}
