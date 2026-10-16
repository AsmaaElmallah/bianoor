import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Pixel tokens for Arena mobile identity (path, tiles, FAB, nav).
abstract final class ArenaIdentity {
  static const Color cream = AppColors.background;
  static const Color ink = AppColors.onSurface;
  static const Color purple = AppColors.primary;
  static const Color green = AppColors.tertiary;
  static const Color orange = AppColors.secondary;
  static const Color pathDot = Color(0xFFFFB4A2);
  static const Color pathLocked = Color(0xFFE8E0F0);
  static const Color activeRing = Color(0xFFFFD54F);
  static const Color botBubble = Color(0xFFEDE4FF);
  static const Color userBubble = Color(0xFFFFF4EC);
  static const Color fabGradientTop = Color(0xFF9B6CFF);
  static const Color fabGradientBottom = Color(0xFF6D4BF3);

  static const double shortcutRadius = 16;
  static const double shortcutWell = 40;
  static const double nodeDone = 64;
  static const double nodeActive = 72;
  static const double nodeLocked = 56;
  static const double fabSize = 56;
  static const double navIcon = 22;
  static const double navLabel = 10;

  static const List<double> pathZigzag = [0, 42, -38, 48, -28, 36, -44, 0];
}
