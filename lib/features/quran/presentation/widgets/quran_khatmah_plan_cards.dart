import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/quran_age_schedule.dart';
import 'tactile/tactile_clay_card.dart';

class _PlanSpec {
  const _PlanSpec({
    required this.title,
    required this.sessionsPerDay,
    required this.daysToFinish,
    required this.highlight,
  });

  final String title;
  final int sessionsPerDay;
  final int daysToFinish;
  final bool highlight;
}

/// Four khatmah plan cards from Stitch _2q design.
class QuranKhatmahPlanCards extends StatelessWidget {
  const QuranKhatmahPlanCards({
    super.key,
    required this.currentKhatmahIndex,
  });

  final int currentKhatmahIndex;

  static const _plans = <_PlanSpec>[
    _PlanSpec(
      title: 'الختمة الأولى',
      sessionsPerDay: 2,
      daysToFinish: 60,
      highlight: true,
    ),
    _PlanSpec(
      title: 'الختمة الثانية',
      sessionsPerDay: 3,
      daysToFinish: 40,
      highlight: false,
    ),
    _PlanSpec(
      title: 'الختمة الثالثة',
      sessionsPerDay: 4,
      daysToFinish: 30,
      highlight: false,
    ),
    _PlanSpec(
      title: 'الختمة الرابعة والخامسة+',
      sessionsPerDay: 5,
      daysToFinish: 24,
      highlight: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'خطة ختم القرآن',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TactileClayCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              _StatChip(icon: Symbols.timer, label: 'نصف حزب / جلسة'),
              _StatChip(icon: Symbols.menu_book, label: '$quranTargetKhatmahCount ختمة'),
              _StatChip(icon: Symbols.celebration, label: 'حتى عمر سنتين'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_plans.length, (i) {
          final plan = _plans[i];
          final isCurrent = switch (i) {
            0 => currentKhatmahIndex == 1,
            1 => currentKhatmahIndex == 2,
            2 => currentKhatmahIndex == 3,
            _ => currentKhatmahIndex >= 4,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanCard(
              plan: plan,
              isCurrent: isCurrent,
            ),
          );
        }),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
  });

  final _PlanSpec plan;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = isCurrent
        ? Border.all(color: AppColors.primary, width: 3)
        : Border.all(color: AppColors.surfaceContainer, width: 2);

    return TactileClayCard(
      color: isCurrent ? AppColors.primaryContainer.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.all(18),
      child: DecoratedBox(
        decoration: BoxDecoration(border: border, borderRadius: AppRadius.brLg),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.brFull,
                      ),
                      child: Text(
                        'الحالية',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _Line(
                icon: Symbols.headphones,
                text: '${plan.sessionsPerDay} جلسات يومياً (نصف حزب)',
              ),
              const SizedBox(height: 6),
              _Line(
                icon: Symbols.calendar_month,
                text: 'الختم في ${plan.daysToFinish} يوماً',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
