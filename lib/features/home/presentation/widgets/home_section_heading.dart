import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class HomeSectionHeading extends StatelessWidget {
  const HomeSectionHeading({
    super.key,
    required this.title,
    required this.accentColor,
    this.art,
  });

  final String title;
  final Color accentColor;
  final String? art;

  @override
  Widget build(BuildContext context) {
    final path = art;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (path != null)
            Image.asset(path, width: 30, height: 30, filterQuality: FilterQuality.medium)
          else
            Container(
              width: 5,
              height: 26,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: AppRadius.brFull,
              ),
            ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.2,
                ),
          ),
        ],
      ),
    );
  }
}
