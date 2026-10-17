import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/arena_identity.dart';
import '../../../../shared/widgets/arena/arena_shortcut_tile.dart';
import '../../../ai/presentation/widgets/ai_launcher.dart';
import '../../../live/domain/live_session.dart';
import '../../../live/presentation/live_sessions_screen.dart';
import '../../application/home_today_journey.dart';
import '../home_shell_screen.dart';

/// Arena-style home block: today plan path + white icon shortcuts + continue.
class HomeTodayJourneySection extends ConsumerWidget {
  const HomeTodayJourneySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(homeTodayJourneyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 16),
          child: _TodayPlanCard(journey: journey),
        ),
        const SizedBox(height: 8),
        Text(
          'ابدئي من هنا',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 10),
        const _ShortcutGrid(),
        if (journey.nextStep != null) ...[
          const SizedBox(height: 14),
          _ContinueCard(step: journey.nextStep!),
        ],
      ],
    );
  }
}

void _openTodayPlan(BuildContext context, WidgetRef ref, HomeTodayJourney journey) {
  final live = journey.upcomingLive;
  if (live != null && live.status == LiveStatus.live) {
    openLiveSession(context, ref, live);
    return;
  }
  // Arena identity: open unified zigzag path (قرآن / بصري / حساب / عاطفي + دورات).
  context.push(AppRoutes.todayLearningPath);
}

class _TodayPlanCard extends ConsumerWidget {
  const _TodayPlanCard({required this.journey});

  final HomeTodayJourney journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final done = journey.doneCount;
    final total = journey.totalCount;
    final next = journey.nextStep;
    final live = journey.upcomingLive;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          bottom: -8,
          child: IgnorePointer(
            child: Image.asset(
              AppAssets.mascotSpoonSitting,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: -8,
          child: IgnorePointer(
            child: Image.asset(
              AppAssets.mascotGirlStanding,
              height: 46,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _openTodayPlan(context, ref, journey),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.todayPlanGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رحلة ${journey.babyName}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            journey.allDone ? 'خطة اليوم خلصت 👏' : 'خطة اليوم جاهزة!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (next != null && !journey.allDone) ...[
                            const SizedBox(height: 6),
                            Text(
                              'الدور: ${next.title}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              next.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Arena-style mascot cue
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.tertiary.withValues(alpha: 0.45),
                              width: 2,
                            ),
                          ),
                        ),
                        Image.asset(
                          AppAssets.mascotCapLying,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Symbols.star,
                            color: AppColors.secondary,
                            size: 40,
                            fill: 1,
                          ),
                        ),
                        if (!journey.allDone)
                          Positioned(
                            top: -18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'يلا نبدأ!',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Four-track path (Arena progress nodes)
                Row(
                  children: [
                    for (var i = 0; i < journey.steps.length; i++) ...[
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                      _TrackNode(
                        step: journey.steps[i],
                        isNext: next?.id == journey.steps[i].id,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '$done من $total',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!journey.allDone)
                      Text(
                        '${journey.minutesLeft} دقايق متبقية',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: AppRadius.brFull,
                      ),
                      child: Text(
                        journey.allDone
                            ? 'راجعي الدروس'
                            : live?.status == LiveStatus.live
                                ? 'ادخلي اللايف'
                                : 'أكملي الرحلة',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (live != null) ...[
                  const SizedBox(height: 12),
                  _LiveInsidePlan(
                    title: live.title,
                    isLive: live.status == LiveStatus.live,
                    when: live.status == LiveStatus.live
                        ? 'مباشر دلوقتي'
                        : live.scheduleLabel ?? 'قريبًا',
                    onTap: () => openLiveSession(context, ref, live),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
        ),
      ],
    );
  }
}

class _TrackNode extends StatelessWidget {
  const _TrackNode({required this.step, required this.isNext});

  final HomeTrackStep step;
  final bool isNext;

  IconData get _icon => switch (step.id) {
        HomeTrackId.quran => Symbols.menu_book,
        HomeTrackId.visual => Symbols.visibility,
        HomeTrackId.math => Symbols.calculate,
        HomeTrackId.emotional => Symbols.favorite,
      };

  @override
  Widget build(BuildContext context) {
    final size = isNext ? 36.0 : 30.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: step.done
            ? ArenaIdentity.green
            : isNext
                ? Colors.white
                : Colors.white.withValues(alpha: 0.22),
        border: isNext && !step.done
            ? Border.all(color: ArenaIdentity.activeRing, width: 3)
            : null,
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: ArenaIdentity.activeRing.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        step.done ? Symbols.check : _icon,
        size: isNext ? 18 : 14,
        color: step.done
            ? Colors.white
            : isNext
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.75),
        weight: 700,
        fill: step.done || isNext ? 1 : 0,
      ),
    );
  }
}

class _LiveInsidePlan extends StatelessWidget {
  const _LiveInsidePlan({
    required this.title,
    required this.isLive,
    required this.when,
    required this.onTap,
  });

  final String title;
  final bool isLive;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isLive ? Symbols.sensors : Symbols.videocam,
                color: isLive ? const Color(0xFFFFB4B4) : Colors.white,
                fill: 1,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLive ? 'بث مباشر · $title' : 'بث قريب · $title · $when',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const Icon(Symbols.chevron_left, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutGrid extends ConsumerWidget {
  const _ShortcutGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <({
      String title,
      IconData icon,
      Color well,
      VoidCallback onTap,
    })>[
      (
        title: 'قرآن',
        icon: Symbols.menu_book,
        well: AppColors.trackQuranGold,
        onTap: () => context.push('/home/quran'),
      ),
      (
        title: 'تحفيز بصري',
        icon: Symbols.visibility,
        well: const Color(0xFF29223F),
        onTap: () => context.push('/home/visual'),
      ),
      (
        title: 'حساب',
        icon: Symbols.calculate,
        well: AppColors.trackMathOrange,
        onTap: () => context.push('/home/math'),
      ),
      (
        title: 'ذكاء عاطفي',
        icon: Symbols.favorite,
        well: AppColors.trackEmotionalRed,
        onTap: () => context.push('/home/emotional'),
      ),
      (
        title: 'مكتبة',
        icon: Symbols.local_library,
        well: AppColors.trackLibraryBlue,
        onTap: () => ref.read(homeTabIndexProvider.notifier).state = 1,
      ),
      (
        title: 'نادي الأمهات',
        icon: Symbols.group,
        well: const Color(0xFF14B8A6),
        onTap: () => context.push(AppRoutes.mothersClub),
      ),
      (
        title: 'سشنات مباشرة',
        icon: Symbols.play_circle,
        well: AppColors.primary,
        onTap: () => ref.read(homeTabIndexProvider.notifier).state = 2,
      ),
      (
        title: 'اسألي بيانور',
        icon: Symbols.smart_toy,
        well: const Color(0xFF9B6CFF),
        onTap: () => showAiChatPopup(context),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 92,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return ArenaShortcutTile(
          title: item.title,
          icon: item.icon,
          wellColor: item.well,
          onTap: item.onTap,
        );
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.step});

  final HomeTrackStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(step.playRoute),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Symbols.play_arrow, color: AppColors.primary, fill: 1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كمّلي: ${step.title}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
