import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/quran_curriculum_provider.dart';
import '../../domain/quran_age_schedule.dart';
import 'tactile/tactile_clay_card.dart';
import 'tactile/tactile_clay_progress.dart';

class QuranProgressCard extends StatelessWidget {
  const QuranProgressCard({super.key, required this.state});

  final QuranCurriculumState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = state.progress;
    final fraction = progress.sessionFractionForKhatmah(progress.currentKhatmahIndex);
    final session = state.currentSession;

    return TactileClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.mic, color: AppColors.primary, fill: 1),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.currentKhatmah.reciter.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'الختمة ${progress.currentKhatmahIndex}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TactileClayProgress(value: fraction),
          const SizedBox(height: 10),
          Text(
            'الجلسة ${progress.currentSessionIndex} من $quranSessionsPerKhatmah',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            session.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ختمات مكتملة: ${progress.completedKhatmahsCount} · ${state.daysPerKhatmah} يوم للختمة الحالية',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
