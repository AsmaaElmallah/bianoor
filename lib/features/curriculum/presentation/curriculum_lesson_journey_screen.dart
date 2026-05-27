import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../quran/presentation/widgets/tactile/quran_journey_node.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../domain/curriculum_journey_config.dart';
import '../domain/curriculum_lesson_journey.dart';

/// مسار الدروس (الدرس ١، ٢، …) — نفس أسلوب رحلة الختمات.
class CurriculumLessonJourneyScreen extends StatelessWidget {
  const CurriculumLessonJourneyScreen({
    super.key,
    required this.config,
    required this.curriculumDay,
    this.unlockAllLessons = false,
    this.supabaseNote,
  });

  final CurriculumJourneyConfig config;
  final int curriculumDay;
  final bool unlockAllLessons;
  final String? supabaseNote;

  @override
  Widget build(BuildContext context) {
    final current = curriculumCurrentLessonNumber(
      curriculumDay,
      lastNewContentDay: config.lastNewContentDay,
      maxLessonNumber: config.maxLessonNumber,
      reviewCycleStartDay: config.reviewCycleStartDay,
    );
    var completedLessons = 0;
    for (var i = 1; i <= config.lessonCount; i++) {
      if (curriculumIsLessonFullyComplete(
        i,
        curriculumDay,
        maxLessonNumber: config.maxLessonNumber,
      )) {
        completedLessons++;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: config.journeyTitle,
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
                      config.journeyHeroTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.journeyHeroSubtitle,
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
          if (supabaseNote != null) ...[
            TactileClayCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.secondaryContainer.withValues(alpha: 0.45),
              child: Text(
                supabaseNote!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          ..._buildLessonNodes(context, current: current, completedLessons: completedLessons),
          const SizedBox(height: 24),
          TactileClayCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                Text(
                  'أنجزت $completedLessons من ${config.lessonCount} درساً',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: AppRadius.brFull,
                  child: LinearProgressIndicator(
                    value: (completedLessons / config.lessonCount).clamp(0.0, 1.0),
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
        ],
      ),
    );
  }

  List<Widget> _buildLessonNodes(
    BuildContext context, {
    required int current,
    required int completedLessons,
  }) {
    final nodes = <Widget>[];

    for (var lessonNum = 1; lessonNum <= config.lessonCount; lessonNum++) {
      final dx = quranJourneyPathOffsets[(lessonNum - 1) % quranJourneyPathOffsets.length];
      final isDone = curriculumIsLessonFullyComplete(
        lessonNum,
        curriculumDay,
        maxLessonNumber: config.maxLessonNumber,
      );
      final isActive = !isDone && lessonNum == current;
      final effectiveUnlock =
          unlockAllLessons || (kDebugMode && curriculumDay >= config.lastNewContentDay);
      final isLocked = effectiveUnlock
          ? false
          : curriculumIsLessonLocked(
              lessonNum,
              curriculumDay,
              lastNewContentDay: config.lastNewContentDay,
              maxLessonNumber: config.maxLessonNumber,
              reviewCycleStartDay: config.reviewCycleStartDay,
            );
      final canOpen = effectiveUnlock || !isLocked;
      final span = curriculumLessonDaySpan(
        lessonNum,
        maxLessonNumber: config.maxLessonNumber,
      );

      nodes.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: QuranJourneyNode(
              label: config.lessonLabel(lessonNum),
              subtitle: '${span.dayCount} يوماً',
              isDone: isDone,
              isActive: isActive,
              isLocked: isLocked,
              isBonus: lessonNum == config.lessonCount,
              speechBubble: canOpen ? (isActive ? 'ابدأ الآن' : 'افتح') : null,
              onTap: canOpen
                  ? () => context.push(config.lessonDaysPath(lessonNum))
                  : null,
            ),
          ),
        ),
      );
    }

    return nodes;
  }
}
