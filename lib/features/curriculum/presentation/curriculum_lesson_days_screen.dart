import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../quran/presentation/widgets/tactile/quran_journey_node.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../domain/curriculum_journey_config.dart';
import '../domain/curriculum_lesson_journey.dart';

/// أيام درس واحد (اليوم الأول، الثاني، …) مع علامة الإنجاز.
class CurriculumLessonDaysScreen extends StatelessWidget {
  const CurriculumLessonDaysScreen({
    super.key,
    required this.config,
    required this.lessonNumber,
    required this.curriculumDay,
    this.slideInfo,
    this.unlockAllLessons = false,
  });

  final CurriculumJourneyConfig config;
  final int lessonNumber;
  final int curriculumDay;
  final String? slideInfo;
  final bool unlockAllLessons;

  @override
  Widget build(BuildContext context) {
    final span = curriculumLessonDaySpan(
      lessonNumber,
      maxLessonNumber: config.maxLessonNumber,
    );
    final totalDays = span.dayCount;
    final completedDays = curriculumCompletedDaysInLesson(
      lessonNumber,
      curriculumDay,
      maxLessonNumber: config.maxLessonNumber,
    );
    final currentDayInLesson = curriculumCurrentDayIndexInLesson(
      lessonNumber,
      curriculumDay,
      maxLessonNumber: config.maxLessonNumber,
    );
    final remaining = curriculumRemainingDaysInLesson(
      lessonNumber,
      curriculumDay,
      maxLessonNumber: config.maxLessonNumber,
    );
    final lessonDone = curriculumIsLessonFullyComplete(
      lessonNumber,
      curriculumDay,
      maxLessonNumber: config.maxLessonNumber,
    );
    final isCurrentLesson = curriculumCurrentLessonNumber(
          curriculumDay,
          lastNewContentDay: config.lastNewContentDay,
          maxLessonNumber: config.maxLessonNumber,
          reviewCycleStartDay: config.reviewCycleStartDay,
        ) ==
        lessonNumber;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: config.lessonLabel(lessonNumber),
        onBack: () => context.pop(),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: totalDays + 1,
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
                            config.headerIcon,
                            size: 96,
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خطة ${config.lessonLabel(lessonNumber)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalDays يوماً · من اليوم ${span.startDay} إلى ${span.endDay}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (slideInfo != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                slideInfo!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
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
                          lessonDone
                              ? 'أكملت كل أيام هذا الدرس'
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

          final dayInLesson = index;
          final dx = quranJourneyPathOffsets[(dayInLesson - 1) % quranJourneyPathOffsets.length];
          final isDone = dayInLesson <= completedDays;
          final isActive = !unlockAllLessons &&
              isCurrentLesson &&
              !lessonDone &&
              dayInLesson == currentDayInLesson;
          final isLocked = !unlockAllLessons && !isDone && !isActive;
          final canPlay = unlockAllLessons || isActive || isDone;

          String? subtitle;
          if (isDone) {
            subtitle = unlockAllLessons ? 'مكتمل · إعادة' : 'مكتمل';
          } else if (isActive) {
            subtitle = 'اليوم الحالي';
          } else if (unlockAllLessons) {
            subtitle = 'متاح للتجربة';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Transform.translate(
              offset: Offset(dx, 0),
              child: QuranJourneyNode(
                label: curriculumLessonDayLabel(dayInLesson),
                subtitle: subtitle,
                isDone: isDone,
                isActive: isActive || (unlockAllLessons && canPlay && !isDone),
                isLocked: isLocked,
                speechBubble: canPlay ? 'ابدأ الآن' : null,
                onTap: canPlay
                    ? () => context.push(config.playerPathForLesson(lessonNumber))
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
