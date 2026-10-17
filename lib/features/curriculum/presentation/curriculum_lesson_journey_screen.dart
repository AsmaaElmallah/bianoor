import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/arena_identity.dart';
import '../../../shared/widgets/arena/arena_feature_hero.dart';
import '../../../shared/widgets/arena/arena_learning_path.dart';
import '../../subscription/application/premium_access.dart';
import '../domain/curriculum_journey_config.dart';
import '../domain/curriculum_lesson_journey.dart';

/// مسار الدروس — Arena Duolingo path (نفس هوية خطة اليوم).
class CurriculumLessonJourneyScreen extends ConsumerWidget {
  const CurriculumLessonJourneyScreen({
    super.key,
    required this.config,
    required this.curriculumDay,
  });

  final CurriculumJourneyConfig config;
  final int curriculumDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedLessonDaysProvider).valueOrNull;
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

    final nodes = <ArenaPathNodeData>[];
    for (var lessonNum = 1; lessonNum <= config.lessonCount; lessonNum++) {
      final isDone = curriculumIsLessonFullyComplete(
        lessonNum,
        curriculumDay,
        maxLessonNumber: config.maxLessonNumber,
      );
      final isActive = !isDone && lessonNum == current;
      final span = curriculumLessonDaySpan(
        lessonNum,
        maxLessonNumber: config.maxLessonNumber,
      );
      final paid = unlocked != null && span.startDay <= unlocked;
      final isLocked = !paid &&
          curriculumIsLessonLocked(
            lessonNum,
            curriculumDay,
            lastNewContentDay: config.lastNewContentDay,
            maxLessonNumber: config.maxLessonNumber,
            reviewCycleStartDay: config.reviewCycleStartDay,
          );
      final needsPlan = isActive && unlocked != null && curriculumDay > unlocked;
      final canOpen = !isLocked;

      nodes.add(
        ArenaPathNodeData(
          id: 'lesson_$lessonNum',
          title: config.lessonLabel(lessonNum),
          subtitle: isDone
              ? 'مكتمل · ${span.dayCount} ي'
              : isActive
                  ? (needsPlan ? 'مدّي الاشتراك' : 'درس اليوم · ${span.dayCount} ي')
                  : isLocked
                      ? 'يُفتح بعد اشتراك'
                      : '${span.dayCount} يوماً',
          state: isDone
              ? ArenaPathNodeState.done
              : isActive
                  ? ArenaPathNodeState.active
                  : isLocked
                      ? ArenaPathNodeState.locked
                      : ArenaPathNodeState.upcoming,
          accent: AppColors.tertiary,
          icon: config.headerIcon,
          characterAsset: AppAssets.mascotAt(lessonNum - 1),
          speechBubble: isActive
              ? (needsPlan ? 'مدّي الاشتراك' : 'درسنا النهارده!')
              : null,
          onTap: needsPlan || isLocked
              ? () => openPlansForLessons(context, ref)
              : canOpen
                  ? () => context.push(config.lessonDaysPath(lessonNum))
                  : null,
        ),
      );
    }

    final progress = config.lessonCount == 0 ? 0.0 : completedLessons / config.lessonCount;

    return Scaffold(
      backgroundColor: ArenaIdentity.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.onSurface),
                  ),
                  Expanded(
                    child: Text(
                      config.journeyTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                children: [
                  ArenaFeatureHero(
                    title: config.journeyHeroTitle,
                    description: config.journeyHeroSubtitle,
                    icon: config.headerIcon,
                    background: config.arenaHeroColor,
                    badge: config.arenaBadge,
                    tags: config.arenaTags,
                    iconWellColor: config.arenaIconWell,
                    child: config.arenaShowContrastTiles
                        ? const ArenaContrastTiles()
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ArenaLearningPath(
                    unitBadge: config.journeyTitle,
                    unitTitle: config.journeyHeroTitle,
                    unitSubtitle: config.journeyHeroSubtitle,
                    progressLabel: '$completedLessons من ${config.lessonCount} دروس مكتملة',
                    progressValue: progress,
                    nodes: nodes,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
