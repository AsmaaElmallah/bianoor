import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/arena_identity.dart';
import '../../../shared/widgets/arena/arena_feature_hero.dart';
import '../../../shared/widgets/arena/arena_learning_path.dart';
import '../../subscription/application/premium_access.dart';
import '../application/quran_curriculum_provider.dart';
import '../domain/quran_age_schedule.dart';

/// Quran khatmah map — Arena Duolingo path identity.
class QuranJourneyScreen extends ConsumerWidget {
  const QuranJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranCurriculumProvider);
    final progress = state.progress;
    final completed = progress.completedKhatmahsCount;
    final current = progress.currentKhatmahIndex;
    final unlocked = ref.watch(unlockedLessonDaysProvider).valueOrNull;

    const showCount = 5;
    final nodes = <ArenaPathNodeData>[];
    for (var i = 0; i < showCount; i++) {
      final khatmahNum = i + 1;
      final isDone = khatmahNum <= completed;
      final isActive = !isDone && khatmahNum == current;
      final paid = unlocked != null && quranCumulativeDay(khatmahNum, 1) <= unlocked;
      final isLocked = khatmahNum > current && !paid;
      final canOpen = !isLocked;

      nodes.add(
        ArenaPathNodeData(
          id: 'khatmah_$khatmahNum',
          title: 'الختمة $khatmahNum',
          subtitle: isDone
              ? 'مكتمل'
              : isActive
                  ? 'درس اليوم'
                  : isLocked
                      ? 'يُفتح بعد اشتراك'
                      : 'جاهزة',
          state: isDone
              ? ArenaPathNodeState.done
              : isActive
                  ? ArenaPathNodeState.active
                  : isLocked
                      ? ArenaPathNodeState.locked
                      : ArenaPathNodeState.upcoming,
          accent: AppColors.trackQuranGold,
          icon: Symbols.menu_book,
          characterAsset: AppAssets.mascotAt(i),
          speechBubble: isActive
              ? 'درسنا النهارده!'
              : isLocked
                  ? 'مدّي عشان تفتح'
                  : null,
          onTap: isLocked
              ? () => openPlansForLessons(context, ref)
              : canOpen
                  ? () => context.push(AppRoutes.quranKhatmahDaysPath(khatmahNum))
                  : null,
        ),
      );
    }

    final progressValue = (completed / quranTargetKhatmahCount).clamp(0.0, 1.0);

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
                      'رحلة الختمات',
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
                    title: 'دروس القرآن الكريم',
                    description:
                        'آيات قصيرة مختارة بصوتٍ عذب، مع جلسات تحفيظ هادئة تناسب انتباه الرضيع.',
                    icon: Symbols.menu_book,
                    background: AppColors.primary,
                    badge: 'الأكثر استخداماً',
                    child: ArenaMiniPlayerStrip(
                      title: state.currentSession.title,
                      subtitle: 'جلسة هادئة · ٣ دقائق',
                      progressLabel: 'كمّلي جلسة النهارده',
                      progress: progressValue,
                      onPlay: () => context.push(AppRoutes.quranPlayer),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ArenaLearningPath(
                    unitBadge: 'القسم 1: البداية',
                    unitTitle: 'أول خطوات مع القرآن',
                    unitSubtitle: 'بُلبُل · مدرّب القرآن · رحلتك نحو $quranTargetKhatmahCount ختمة',
                    progressLabel: '$completed من $quranTargetKhatmahCount ختمة مكتملة',
                    progressValue: progressValue,
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
