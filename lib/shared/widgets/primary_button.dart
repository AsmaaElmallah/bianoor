import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

/// Pill-shaped CTA. Optional [gradient] overrides brand gradient (e.g. BeBo purple / lavender).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconLeading = false,
    this.fullWidth = true,
    this.height = 58,
    this.gradient,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool iconLeading;
  final bool fullWidth;
  final double height;
  final Gradient? gradient;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final fg = foregroundColor ?? AppColors.onPrimary;

    return Opacity(
      opacity: isEnabled ? 1 : 0.48,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient ?? AppColors.primaryGradient,
              borderRadius: AppRadius.brLg,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1,
              ),
              boxShadow: isEnabled ? AppShadows.clayPrimaryButton : null,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: AppRadius.brLg,
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null && iconLeading) ...[
                      Icon(icon, color: fg, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: fg),
                      ),
                    ),
                    if (icon != null && !iconLeading) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: fg, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
