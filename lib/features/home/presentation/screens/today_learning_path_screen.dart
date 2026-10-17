import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/arena_identity.dart';
import '../../../../shared/widgets/arena/arena_learning_path.dart';
import '../../../live/domain/live_session.dart';
import '../../../live/presentation/live_sessions_screen.dart';
import '../../application/home_today_journey.dart';
import '../home_shell_screen.dart';

/// Arena «رحلة التعلم / درس تفاعلي» — opened from خطة اليوم.
class TodayLearningPathScreen extends ConsumerWidget {
  const TodayLearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(homeTodayJourneyProvider);
    final theme = Theme.of(context);
    final next = journey.nextStep;
    final done = journey.doneCount;
    final total = journey.totalCount;
    final progress = total == 0 ? 0.0 : done / total;

    Color accentFor(HomeTrackId id) => switch (id) {
          HomeTrackId.quran => AppColors.trackQuranGold,
          HomeTrackId.visual => AppColors.trackVisualPurple,
          HomeTrackId.math => AppColors.trackMathOrange,
          HomeTrackId.emotional => AppColors.trackEmotionalRed,
        };

    IconData iconFor(HomeTrackId id) => switch (id) {
          HomeTrackId.quran => Symbols.menu_book,
          HomeTrackId.visual => Symbols.visibility,
          HomeTrackId.math => Symbols.calculate,
          HomeTrackId.emotional => Symbols.favorite,
        };

    final nodes = <ArenaPathNodeData>[
      for (final step in journey.steps)
        ArenaPathNodeData(
          id: step.id.name,
          title: step.title,
          subtitle: step.done
              ? 'مكتمل'
              : next?.id == step.id
                  ? 'درس اليوم'
                  : step.subtitle,
          state: step.done
              ? ArenaPathNodeState.done
              : next?.id == step.id
                  ? ArenaPathNodeState.active
                  : ArenaPathNodeState.locked,
          accent: accentFor(step.id),
          icon: iconFor(step.id),
          characterAsset: AppAssets.mascotForTrack(step.id.name),
          speechBubble: next?.id == step.id ? 'درسنا النهارده!' : null,
          onTap: () {
            if (step.done || next?.id == step.id) {
              context.push(step.playRoute);
            } else {
              context.push(step.route);
            }
          },
        ),
    ];

    final live = journey.upcomingLive;
    if (live != null) {
      final isLive = live.status == LiveStatus.live;
      nodes.add(
        ArenaPathNodeData(
          id: 'live',
          title: live.title,
          subtitle: isLive ? 'مباشر دلوقتي' : (live.scheduleLabel ?? 'قريبًا'),
          state: isLive ? ArenaPathNodeState.active : ArenaPathNodeState.upcoming,
          accent: AppColors.primary,
          icon: Symbols.videocam,
          characterAsset: AppAssets.mascotForTrack('live'),
          speechBubble: isLive ? 'ادخلي اللايف!' : null,
          onTap: () => openLiveSession(context, ref, live),
        ),
      );
    }

    nodes.add(
      ArenaPathNodeData(
        id: 'courses',
        title: 'الدورات والسشنات',
        subtitle: 'تابعي مع المدرسات',
        state: ArenaPathNodeState.upcoming,
        accent: AppColors.secondary,
        icon: Symbols.school,
        characterAsset: AppAssets.mascotForTrack('courses'),
        onTap: () {
          Navigator.of(context).pop();
          ref.read(homeTabIndexProvider.notifier).state = 2;
        },
      ),
    );

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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.onSurface),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رحلة ${journey.babyName}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'خطة اليوم · $done من $total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatChip(icon: Symbols.local_fire_department, label: '$done', color: ArenaIdentity.orange),
                  const SizedBox(width: 6),
                  _StatChip(icon: Symbols.favorite, label: '${(total - done).clamp(0, 9)}', color: AppColors.error),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  ArenaLearningPath(
                    unitBadge: 'خطة اليوم',
                    unitTitle: journey.allDone ? 'أحسنتِ! خلصتِ اليوم' : 'أول خطوات مبهجة',
                    unitSubtitle: 'قرآن · تحفيز بصري · حساب · ذكاء عاطفي',
                    progressLabel: '$done من $total دروس مكتملة',
                    progressValue: progress,
                    nodes: nodes,
                  ),
                  if (next != null && !journey.allDone) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FilledButton(
                        onPressed: () => context.push(next.playRoute),
                        style: FilledButton.styleFrom(
                          backgroundColor: ArenaIdentity.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'كمّلي درس اليوم',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color, fill: 1),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
