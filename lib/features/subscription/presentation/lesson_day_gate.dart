import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../application/premium_access.dart';

/// Shows [child] only when the curriculum day from [day] is unlocked by a paid plan.
class LessonDayGate extends ConsumerWidget {
  const LessonDayGate({
    super.key,
    required this.title,
    required this.day,
    required this.child,
  });

  final String title;
  final AsyncValue<int> Function(WidgetRef ref) day;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedLessonDaysProvider);
    final needed = day(ref);
    if (unlocked is AsyncData<int> && needed is AsyncData<int>) {
      if (needed.value <= unlocked.value) return child;
      return LessonLockedView(title: title, day: needed.value, unlocked: unlocked.value);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: title, onBack: () => context.pop()),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class LessonLockedView extends ConsumerWidget {
  const LessonLockedView({
    super.key,
    required this.title,
    required this.day,
    required this.unlocked,
  });

  final String title;
  final int day;
  final int unlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: title, onBack: () => context.pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: TactileClayCard(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Symbols.lock,
                        size: 42,
                        fill: 1,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      unlocked <= 0 ? 'الدروس محتاجة باقة' : 'اليوم $day لسه مقفول',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lessonLockedReason(unlocked),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: lessonExtendCtaLabel(unlocked),
                      onPressed: () => openPlansForLessons(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
