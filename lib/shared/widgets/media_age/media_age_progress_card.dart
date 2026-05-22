import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../tactile/tactile_clay_card.dart';
import '../tactile/tactile_clay_progress.dart';

class MediaAgeProgressCard extends StatelessWidget {
  const MediaAgeProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.total,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final int current;
  final int total;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : current / total;
    final percent = (progress * 100).round();

    return TactileClayCard(
      color: AppColors.primaryContainer.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.isEmpty
                          ? 'لقد أكملت $percent% من المجموعة'
                          : subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryContainer, width: 4),
                  boxShadow: AppShadows.soft,
                ),
                alignment: Alignment.center,
                child: Text(
                  total == 0 ? '—' : '$current/$total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TactileClayProgress(value: progress, height: 16),
        ],
      ),
    );
  }
}
