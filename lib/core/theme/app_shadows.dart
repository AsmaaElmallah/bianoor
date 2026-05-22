import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  /// Warm "clay" lift — soft highlight + warm diffuse depth.
  static List<BoxShadow> clayLift = [
    BoxShadow(
      color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
      blurRadius: 0,
      offset: const Offset(-0.5, -1.5),
    ),
    BoxShadow(
      color: const Color(0xFFC8906A).withValues(alpha: 0.1), // warm brown shadow
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFFC8906A).withValues(alpha: 0.06),
      blurRadius: 36,
      spreadRadius: -6,
      offset: const Offset(0, 14),
    ),
  ];

  /// Primary CTA: warm clay depth + brand teal glow.
  static List<BoxShadow> get clayPrimaryButton => [
        ...clayLift,
        ...primaryGlow,
      ];

  static List<BoxShadow> editorial = [
    BoxShadow(
      color: const Color(0xFFC8906A).withValues(alpha: 0.08),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFFC8906A).withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.22),
      blurRadius: 24,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> bottomNav = [
    BoxShadow(
      color: const Color(0xFFC8906A).withValues(alpha: 0.12),
      blurRadius: 32,
      spreadRadius: 0,
      offset: const Offset(0, -6),
    ),
    BoxShadow(
      color: const Color(0xFFC8906A).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, -2),
    ),
  ];

  /// Card shadow with warm tint
  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFFC8906A).withValues(alpha: 0.09),
      blurRadius: 16,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
      blurRadius: 0,
      offset: const Offset(-1, -1),
    ),
  ];
}
