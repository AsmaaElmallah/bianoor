import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../application/quran_curriculum_provider.dart';
import 'widgets/quran_khatmah_plan_cards.dart';
import 'widgets/quran_progress_card.dart';
import 'widgets/tactile/quran_tactile_app_bar.dart';
import 'widgets/tactile/tactile_clay_button.dart';
import 'widgets/tactile/tactile_clay_card.dart';

class QuranLessonScreen extends ConsumerWidget {
  const QuranLessonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranCurriculumProvider);
    final theme = Theme.of(context);
    final canListen = ref.read(quranCurriculumProvider.notifier).canStartAnotherSessionToday();
    final progress = state.progress;
    final stars = progress.completedKhatmahsCount * 120 + progress.currentSessionIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'القرآن الكريم',
        showStars: true,
        starsCount: stars,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          QuranProgressCard(state: state),
          const SizedBox(height: 20),
          QuranKhatmahPlanCards(currentKhatmahIndex: progress.currentKhatmahIndex),
          const SizedBox(height: 20),
          Text(
            'الدرس الحالي',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          TactileClayCard(
            onTap: canListen ? () => context.push(AppRoutes.quranPlayer) : null,
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: AppRadius.brXl,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.tertiaryContainer],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Symbols.menu_book,
                      size: 64,
                      color: AppColors.primary,
                      fill: 1,
                    ),
                    Positioned(
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
                          borderRadius: AppRadius.brFull,
                        ),
                        child: Text(
                          state.currentSession.title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TactileClayButton(
            label: 'مسار الختمات التفاعلي',
            icon: Symbols.route,
            backgroundColor: AppColors.tertiary,
            depthColor: AppColors.tertiaryDim,
            onPressed: () => context.push(AppRoutes.quranJourney),
          ),
          const SizedBox(height: 12),
          if (!canListen)
            TactileClayCard(
              color: AppColors.secondaryContainer.withValues(alpha: 0.45),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Symbols.check_circle, color: AppColors.secondary, fill: 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أكملت جلسات اليوم (${state.dailyRepetitions} جلسات). عد غداً بإذن الله.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!canListen) const SizedBox(height: 12),
          TactileClayButton(
            label: canListen ? 'ابدأ جلسة اليوم' : 'جلسات اليوم مكتملة',
            icon: Symbols.headphones,
            onPressed: canListen ? () => context.push(AppRoutes.quranPlayer) : null,
          ),
        ],
      ),
    );
  }
}
