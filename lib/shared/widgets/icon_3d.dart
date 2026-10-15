import 'package:flutter/material.dart';

import '../../core/constants/app_art.dart';
import '../../core/theme/app_colors.dart';

/// Shows a 3D art asset — [art], or the 3D match for [icon] — and falls back
/// to the flat [icon] when there's none.
class Icon3D extends StatelessWidget {
  const Icon3D({
    super.key,
    required this.art,
    required this.icon,
    this.size = 40,
    this.color,
  });

  final String? art;
  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(icon, size: size * 0.7, color: color ?? AppColors.primary, fill: 1);
    final path = art ?? AppArt.forIcon(icon);
    if (path == null) return SizedBox.square(dimension: size, child: Center(child: fallback));
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => SizedBox.square(dimension: size, child: Center(child: fallback)),
    );
  }
}
