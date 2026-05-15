import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography using Tajawal for Arabic text.
/// Sizes are calibrated to match the HTML reference designs visually —
/// Tajawal renders larger than Plus Jakarta Sans so we scale down.
class AppTypography {
  AppTypography._();

  static TextStyle _t({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.onSurface,
    double letterSpacing = 0,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: 'XPNiloofar',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextTheme buildTextTheme() {
    return TextTheme(
      // Display — used ONLY for the app name on Splash
      displayLarge:  _t(size: 38, weight: FontWeight.w900, letterSpacing: -0.5, height: 1.1),
      displayMedium: _t(size: 32, weight: FontWeight.w800, letterSpacing: -0.35, height: 1.13),
      displaySmall:  _t(size: 28, weight: FontWeight.w800, letterSpacing: -0.2, height: 1.16),

      // Headline — page titles
      headlineLarge:  _t(size: 28, weight: FontWeight.w800, letterSpacing: -0.18, height: 1.18),
      headlineMedium: _t(size: 24, weight: FontWeight.w700, height: 1.22),
      headlineSmall:  _t(size: 20, weight: FontWeight.w700, height: 1.24),

      // Title — section headers, card titles
      titleLarge:  _t(size: 18, weight: FontWeight.w700, height: 1.26),
      titleMedium: _t(size: 16, weight: FontWeight.w600, height: 1.28),
      titleSmall:  _t(size: 14, weight: FontWeight.w600, height: 1.3),

      // Body — paragraph text
      bodyLarge:  _t(size: 15, weight: FontWeight.w500, height: 1.55),
      bodyMedium: _t(size: 14, weight: FontWeight.w400, height: 1.55, color: AppColors.onSurfaceVariant),
      bodySmall:  _t(size: 12, weight: FontWeight.w400, height: 1.5, color: AppColors.onSurfaceVariant),

      // Label — buttons, chips, tags
      labelLarge:  _t(size: 16, weight: FontWeight.w700, height: 1.2),
      labelMedium: _t(size: 13, weight: FontWeight.w600, height: 1.25),
      labelSmall:  _t(size: 11, weight: FontWeight.w600, letterSpacing: 0.2, height: 1.25),
    );
  }
}
