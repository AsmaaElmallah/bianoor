import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../application/quran_curriculum_provider.dart';
import '../domain/quran_age_schedule.dart';
import 'widgets/tactile/quran_journey_node.dart';
import 'widgets/tactile/quran_tactile_app_bar.dart';
import 'widgets/tactile/tactile_clay_card.dart';

/// Daily roadmap inside one khatmah (اليوم الأول، الثاني، …).
class QuranKhatmahDaysScreen extends ConsumerWidget {
  const QuranKhatmahDaysScreen({super.key, required this.khatmahIndex});

  final int khatmahIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranCurriculumProvider);
    final progress = state.progress;
    final daily = dailySessionsForKhatmah(khatmahIndex);
    final totalDays = daysPerKhatmahForIndex(khatmahIndex);
    final completedDays = completedDaysForKhatmah(progress, khatmahIndex);
    final currentDay = currentDayForKhatmah(progress, khatmahIndex);
    final remaining = remainingDaysForKhatmah(progress, khatmahIndex);
    final khatmahDone = isKhatmahFullyComplete(progress, khatmahIndex);
    final isCurrentKhatmah = khatmahIndex == progress.currentKhatmahIndex;
    final partialToday =
        isCurrentKhatmah ? sessionsDoneOnCurrentDay(progress, khatmahIndex) : 0;
    final stars = progress.completedKhatmahsCount * 120 + progress.currentSessionIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'الختمة $khatmahIndex',
        showStars: true,
        starsCount: stars,
        onBack: () => context.pop(),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: totalDays + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TactileClayCard(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    child: Stack(
                      children: [
                        Positioned(
                          left: -8,
                          bottom: -12,
                          child: Icon(
                            Symbols.calendar_month,
                            size: 96,
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خطة الختمة $khatmahIndex',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalDays يوم · $daily جلسات يومياً',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TactileClayCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
                      children: [
                        Text(
                          khatmahDone
                              ? 'أكملت كل أيام هذه الختمة'
                              : 'أنجزت $completedDays من $totalDays يوم · متبقي $remaining',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: AppRadius.brFull,
                          child: LinearProgressIndicator(
                            value: (completedDays / totalDays).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: AppColors.surfaceContainer,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (index == totalDays + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Transform.translate(
                offset: const Offset(0, 0),
                child: QuranJourneyNode(
                  label: 'مكافأة الختمة',
                  isDone: khatmahDone,
                  isActive: false,
                  isLocked: !khatmahDone,
                  isBonus: true,
                ),
              ),
            );
          }

          final day = index;
          final dx = quranJourneyPathOffsets[(day - 1) % quranJourneyPathOffsets.length];
          final isDone = day <= completedDays;
          final isActive = isCurrentKhatmah && !khatmahDone && day == currentDay;
          final isLocked = !isDone && !isActive;

          String? subtitle;
          if (isActive && partialToday > 0) {
            subtitle = 'جلسة $partialToday من $daily';
          } else if (isDone) {
            subtitle = '$daily جلسات مكتملة';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Transform.translate(
              offset: Offset(dx, 0),
              child: QuranJourneyNode(
                label: quranDayLabel(day),
                subtitle: subtitle,
                isDone: isDone,
                isActive: isActive,
                isLocked: isLocked,
                speechBubble: isActive ? 'ابدأ الآن' : null,
                onTap: isActive
                    ? () => context.push(AppRoutes.quranPlayer)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
