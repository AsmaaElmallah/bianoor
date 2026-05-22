import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import 'widgets/tactile/quran_floating_hero.dart';
import 'widgets/tactile/tactile_clay_button.dart';
import 'widgets/tactile/tactile_clay_card.dart';

/// Khatmah completion celebration (3dq tactile design).
class QuranKhatmahCelebrationScreen extends StatelessWidget {
  const QuranKhatmahCelebrationScreen({
    super.key,
    required this.completedKhatmahIndex,
  });

  final int completedKhatmahIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          ..._confetti(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: QuranCelebrationHeader(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Transform.scale(
                            scale: 0.85,
                            child: const QuranFloatingHero(),
                          ),
                          TactileClayCard(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                    boxShadow: AppShadows.primaryGlow,
                                  ),
                                  child: const Icon(
                                    Symbols.menu_book,
                                    size: 48,
                                    color: AppColors.primary,
                                    fill: 1,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'مبارك يا بطل!',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'تم ختم القرآن الكريم',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest,
                                    borderRadius: AppRadius.brFull,
                                    border: Border.all(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.onSurface.withValues(alpha: 0.05),
                                        offset: const Offset(2, 2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'الختمة $completedKhatmahIndex',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'أتممت رحلة الاستماع المباركة بنجاح. هنيئاً لك هذا الإنجاز العظيم!',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                TactileClayButton(
                                  label: 'ابدأ الختمة التالية',
                                  icon: Symbols.menu_book,
                                  onPressed: () {
                                    context.go(AppRoutes.quranJourney);
                                  },
                                ),
                                const SizedBox(height: 12),
                                TactileClayButton(
                                  label: 'شارك هذا الإنجاز',
                                  icon: Symbols.share,
                                  backgroundColor: AppColors.secondaryContainer,
                                  foregroundColor: AppColors.onSecondaryContainer,
                                  depthColor: AppColors.secondaryDim,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _confetti() {
    const icons = [
      Symbols.grade,
      Symbols.auto_awesome,
      Symbols.favorite,
    ];
  const colors = [
      AppColors.secondaryContainer,
      AppColors.primaryContainer,
      AppColors.tertiaryContainer,
    ];
    return List.generate(icons.length, (i) {
      return Positioned(
        top: 80.0 + i * 60,
        left: i.isEven ? 24 : null,
        right: i.isOdd ? 24 : null,
        child: Icon(
          icons[i],
          size: 32 + i * 8,
          color: colors[i].withValues(alpha: 0.7),
        ),
      );
    });
  }
}

class QuranCelebrationHeader extends StatelessWidget {
  const QuranCelebrationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'بيانور',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }
}
