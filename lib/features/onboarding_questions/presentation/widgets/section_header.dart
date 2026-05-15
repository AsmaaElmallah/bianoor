import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconBg = AppColors.primaryContainer,
    this.iconColor = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: AppRadius.brMd,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 28, fill: 1),
        ),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
