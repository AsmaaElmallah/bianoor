import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../quran/presentation/widgets/tactile/quran_journey_node.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../../subscription/application/premium_access.dart';
import '../domain/curriculum_journey_config.dart';
import '../domain/curriculum_lesson_journey.dart';

/// مسار الدروس (الدرس ١، ٢، …) — نفس أسلوب رحلة الختمات.
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
          const SizedBox(height: 28),
          ..._buildLessonNodes(
            context,
            ref,
            current: current,
            completedLessons: completedLessons,
            unlocked: unlocked,
          ),
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
    BuildContext context,
    WidgetRef ref, {
    required int current,
    required int completedLessons,
    required int? unlocked,
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
      final canOpen = !isLocked;
      final needsPlan = isActive && unlocked != null && curriculumDay > unlocked;

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
              needsPlan: needsPlan,
              speechBubble: isActive ? (needsPlan ? 'افتحي بالباقة' : 'ابدأ الآن') : null,
              onTap: needsPlan
                  ? () => openPlansForLessons(context, ref)
                  : canOpen
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
