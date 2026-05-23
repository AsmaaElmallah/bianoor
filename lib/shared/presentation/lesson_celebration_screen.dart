import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_assets.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../widgets/bebo_shell_background.dart';
import '../widgets/floating_decoration.dart';
import '../widgets/tactile/tactile_clay_button.dart';
import '../widgets/tactile/tactile_clay_card.dart';

/// احتفال بإكمال جولة درس (رياضيات / بصري / عاطفي).
class LessonCelebrationScreen extends StatelessWidget {
  const LessonCelebrationScreen({super.key, required this.track});

  final String track;

  static LessonCelebrationConfig configFor(String track) {
    switch (track) {
      case 'math':
        return const LessonCelebrationConfig(
          title: 'مبارك يا بطل!',
          subtitle: 'أتممت جولة الحساب بنجاح',
          body: 'استمري في التكرار اليومي — كل جولة تقرّب طفلك من إتقان الأرقام والأشكال.',
          icon: Symbols.calculate,
          accent: AppColors.trackMathOrange,
          accentLight: AppColors.trackMathLight,
          journeyRoute: AppRoutes.mathJourney,
          mascotAsset: AppAssets.mascotSpoonSitting,
        );
      case 'visual':
        return const LessonCelebrationConfig(
          title: 'رائع جداً!',
          subtitle: 'أتممت جولة التعلم البصري',
          body: 'عين طفلك تتعلّم من خلال الألوان والأشكال — استمري في نفس الإيقاع اللطيف.',
          icon: Symbols.visibility,
          accent: AppColors.trackVisualPurple,
          accentLight: AppColors.trackVisualLight,
          journeyRoute: AppRoutes.visualJourney,
          mascotAsset: AppAssets.mascotGirlStanding,
        );
      case 'emotional':
        return const LessonCelebrationConfig(
          title: 'أحسنتِ!',
          subtitle: 'أتممت جولة الذكاء العاطفي',
          body: 'مشاعر طفلك تنمو مع كل تمرين — شاركي الفرح معه بعد كل جولة.',
          icon: Symbols.favorite,
          accent: AppColors.trackEmotionalRed,
          accentLight: AppColors.trackEmotionalLight,
          journeyRoute: AppRoutes.emotionalJourney,
          mascotAsset: AppAssets.mascotCapLying,
        );
      default:
        return const LessonCelebrationConfig(
          title: 'مبارك!',
          subtitle: 'أتممت الدرس',
          body: 'استمري في رحلة التعلّم مع بيانور.',
          icon: Symbols.celebration,
          accent: AppColors.primary,
          accentLight: AppColors.primaryContainer,
          journeyRoute: AppRoutes.home,
          mascotAsset: AppAssets.mascotCupLying,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = configFor(track);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const BeboShellBackground(),
          ..._confetti(cfg.accent),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _CelebrationBrand(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          FloatingDecoration(
                            child: Image.asset(
                              cfg.mascotAsset,
                              height: 160,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox(height: 120),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TactileClayCard(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: cfg.accentLight.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                    boxShadow: AppShadows.primaryGlow,
                                  ),
                                  child: Icon(
                                    cfg.icon,
                                    size: 48,
                                    color: cfg.accent,
                                    fill: 1,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  cfg.title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cfg.subtitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cfg.accent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  cfg.body,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                TactileClayButton(
                                  label: 'الجولة التالية',
                                  icon: Symbols.play_arrow,
                                  onPressed: () => context.go(cfg.journeyRoute),
                                ),
                                const SizedBox(height: 12),
                                TactileClayButton(
                                  label: 'العودة للرئيسية',
                                  icon: Symbols.home,
                                  backgroundColor: AppColors.secondaryContainer,
                                  foregroundColor: AppColors.onSecondaryContainer,
                                  depthColor: AppColors.secondaryDim,
                                  onPressed: () => context.go(AppRoutes.home),
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

  List<Widget> _confetti(Color accent) {
    const icons = [Symbols.grade, Symbols.auto_awesome, Symbols.favorite];
    return List.generate(icons.length, (i) {
      return Positioned(
        top: 80.0 + i * 60,
        left: i.isEven ? 24 : null,
        right: i.isOdd ? 24 : null,
        child: Icon(
          icons[i],
          size: 32 + i * 8,
          color: accent.withValues(alpha: 0.45),
        ),
      );
    });
  }
}

class LessonCelebrationConfig {
  const LessonCelebrationConfig({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    required this.accent,
    required this.accentLight,
    required this.journeyRoute,
    required this.mascotAsset,
  });

  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final String journeyRoute;
  final String mascotAsset;
}

class _CelebrationBrand extends StatelessWidget {
  const _CelebrationBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'بيانور',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
      ),
    );
  }
}
