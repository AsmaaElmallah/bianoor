import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

/// Soft-action button with secondary container background.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        boxShadow: onPressed != null ? AppShadows.clayLift : null,
      ),
      child: Material(
        color: AppColors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.42),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.brLg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.onSurface),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: AppColors.onSurface, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
