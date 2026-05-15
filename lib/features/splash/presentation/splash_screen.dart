import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/floating_decoration.dart';
import '../../../shared/widgets/pebble_progress.dart';
import '../../../shared/widgets/primary_button.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(prefsServiceProvider);
      if (prefs.isOnboardingComplete()) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go(AppRoutes.home);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          Positioned(
            top: size.height * 0.06,
            right: 28,
            child: FloatingDecoration(
              amplitude: 20,
              child: Icon(
                Symbols.star,
                size: 78,
                color: AppColors.beboMarketingPurple.withValues(alpha: 0.22),
                fill: 1,
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.22,
            left: 14,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.19,
            left: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 288,
                        height: 288,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.editorial,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 248,
                          height: 248,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.soft,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            AppAssets.logoBaby,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Symbols.child_care,
                              size: 100,
                              color: AppColors.primary,
                              fill: 1,
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: -4,
                        end: -10,
                        child: FloatingDecoration(
                          delay: const Duration(seconds: 1),
                          amplitude: 10,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Symbols.school,
                              color: AppColors.onSecondaryContainer,
                              size: 34,
                              fill: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'المربي اللطيف',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'رحلة تعليمية هادئة وممتعة لطفلك الصغير',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.82),
                    ),
                  ),
                  const Spacer(flex: 2),
                  const PebbleProgress(
                    totalSteps: 3,
                    currentStep: 0,
                    dotSize: 8,
                    activeWidth: 8,
                    spacing: 8,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'ابدأ الرحلة الآن',
                    icon: Symbols.arrow_back,
                    iconLeading: true,
                    fullWidth: true,
                    height: 62,
                    onPressed: () => context.go(AppRoutes.videoIntro),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'LULLABY LEARNING  •  v1.0',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
