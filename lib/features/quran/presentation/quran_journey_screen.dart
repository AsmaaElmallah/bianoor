import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../application/quran_curriculum_provider.dart';
import '../domain/quran_age_schedule.dart';
import 'widgets/tactile/quran_journey_node.dart';
import 'widgets/tactile/quran_tactile_app_bar.dart';
import 'widgets/tactile/tactile_clay_card.dart';

/// Khatmah path map (_3q tactile Play journey).
class QuranJourneyScreen extends ConsumerWidget {
  const QuranJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranCurriculumProvider);
    final progress = state.progress;
    final completed = progress.completedKhatmahsCount;
    final current = progress.currentKhatmahIndex;
    final stars = completed * 120 + progress.currentSessionIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'رحلة الختمات',
        showStars: true,
        starsCount: stars,
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
                    Symbols.menu_book,
                    size: 96,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'القسم 1: البداية',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'رحلتك نحو $quranTargetKhatmahCount ختمة',
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
          ..._buildPathNodes(context, completed: completed, current: current),
          const SizedBox(height: 24),
          TactileClayCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                Text(
                  'تم إنجاز $completed من $quranTargetKhatmahCount ختمة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: AppRadius.brFull,
                  child: LinearProgressIndicator(
                    value: (completed / quranTargetKhatmahCount).clamp(0.0, 1.0),
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

  List<Widget> _buildPathNodes(
    BuildContext context, {
    required int completed,
    required int current,
  }) {
    const showCount = 5;
    final nodes = <Widget>[];

    for (var i = 0; i < showCount; i++) {
      final khatmahNum = i + 1;
      final dx = quranJourneyPathOffsets[i % quranJourneyPathOffsets.length];
      final isDone = khatmahNum <= completed;
      final isActive = !isDone && khatmahNum == current;
      final isLocked = khatmahNum > current;
      final canOpen = !isLocked;

      nodes.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: QuranJourneyNode(
              label: 'الختمة $khatmahNum',
              isDone: isDone,
              isActive: isActive,
              isLocked: isLocked,
              isBonus: khatmahNum == 4,
              speechBubble: isActive ? 'ابدأ الآن' : null,
              onTap: canOpen
                  ? () => context.push(AppRoutes.quranKhatmahDaysPath(khatmahNum))
                  : null,
            ),
          ),
        ),
      );
    }

    return nodes;
  }
}
