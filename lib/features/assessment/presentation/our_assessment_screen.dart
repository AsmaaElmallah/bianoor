import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import 'aptitude_test_screen.dart';
import 'mother_quiz_screen.dart';

class OurAssessmentScreen extends ConsumerWidget {
  const OurAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(prefsServiceProvider);
    final babyName = prefs.getBabyName() ?? 'طفلك';

    final aptitude = prefs.getAptitudeTestAnswers();
    final skills = prefs.getMotherQuizAnswers('skills_test_v1');
    final interests = prefs.getMotherQuizAnswers('interests_test_v1');
    final child = prefs.getMotherQuizAnswers('child_tests_v1');

    final tiles = [
      _AssessmentTile(
        title: 'اختبار القدرات (٠–٢)',
        icon: Symbols.psychology,
        done: aptitude != null && aptitude.isNotEmpty,
        count: aptitude?.length,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AptitudeTestScreen()),
        ),
      ),
      _AssessmentTile(
        title: 'اختبار المهارات',
        icon: Symbols.fact_check,
        done: skills != null && skills.isNotEmpty,
        count: skills?.length,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MotherQuizScreen(quizId: 'skills_test'),
          ),
        ),
      ),
      _AssessmentTile(
        title: 'فحص ميول $babyName',
        icon: Symbols.interests,
        done: interests != null && interests.isNotEmpty,
        count: interests?.length,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MotherQuizScreen(quizId: 'interests_test'),
          ),
        ),
      ),
      _AssessmentTile(
        title: 'اختبارات الطفل',
        icon: Symbols.assignment,
        done: child != null && child.isNotEmpty,
        count: child?.length,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MotherQuizScreen(quizId: 'child_tests'),
          ),
        ),
      ),
    ];

    final completed = tiles.where((t) => t.done).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'تقييمنا',
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                TactileClayCard(
                  child: Row(
                    children: [
                      const Icon(Symbols.verified, color: AppColors.primary, size: 32, fill: 1),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'أكملتِ $completed من ${tiles.length} تقييمات. النتائج محفوظة على جهازك.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...tiles.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AssessmentCard(tile: t),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentTile {
  const _AssessmentTile({
    required this.title,
    required this.icon,
    required this.done,
    required this.onTap,
    this.count,
  });

  final String title;
  final IconData icon;
  final bool done;
  final int? count;
  final VoidCallback onTap;
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.tile});

  final _AssessmentTile tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TactileClayCard(
      onTap: tile.onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (tile.done ? AppColors.primaryContainer : AppColors.surfaceContainerLow)
                  .withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(tile.icon, color: AppColors.primary, fill: 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tile.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  tile.done
                      ? 'مكتمل${tile.count != null ? ' · ${tile.count} إجابة' : ''}'
                      : 'لم يبدأ بعد',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tile.done ? AppColors.primary : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            tile.done ? Symbols.check_circle : Symbols.chevron_left,
            color: tile.done ? AppColors.secondary : AppColors.onSurfaceVariant,
            fill: tile.done ? 1 : 0,
          ),
        ],
      ),
    );
  }
}
