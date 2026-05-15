import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Circular avatar containing the Bayanour mascot icon.
class AppLogoAvatar extends StatelessWidget {
  const AppLogoAvatar({
    super.key,
    this.size = 80,
    this.backgroundColor = AppColors.primaryContainer,
    this.iconColor = AppColors.primary,
    this.icon = Symbols.child_care,
    this.imageAsset = AppAssets.logoBaby,
  });

  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: imageAsset == null
            ? Icon(icon, color: iconColor, size: size * 0.55, fill: 1)
            : Image.asset(
                imageAsset!,
                width: size * 0.88,
                height: size * 0.88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(icon, color: iconColor, size: size * 0.55, fill: 1);
                },
              ),
      ),
    );
  }
}
