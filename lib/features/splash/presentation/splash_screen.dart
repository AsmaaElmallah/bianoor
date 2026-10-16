import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/floating_decoration.dart';
import '../../../shared/widgets/floating_widget.dart';
import '../../../shared/widgets/pebble_progress.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/application/auth_session_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoEnter());
  }

  Future<void> _maybeAutoEnter() async {
    final prefs = ref.read(prefsServiceProvider);
    if (!prefs.isOnboardingComplete()) return;

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (!SupabaseBootstrap.isEnabled) {
      context.go(AppRoutes.home);
      return;
    }

    final auth = ref.read(authSessionProvider);
    if (auth.isLoading) {
      // Wait briefly for session stream, then re-check.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
    }

    final loggedIn = ref.read(authSessionProvider).valueOrNull != null;
    context.go(loggedIn ? AppRoutes.home : AppRoutes.login);
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final circle = (constraints.maxHeight * 0.38).clamp(140.0, 292.0);
                  final mascot = circle * 0.79;
                  final badge = (circle * 0.23).clamp(40.0, 68.0);
                  final gap = constraints.maxHeight < 520 ? 16.0 : 48.0;
                  return Column(
                children: [
                  const Spacer(flex: 2),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Warm gradient circle background
                      Container(
                        width: circle,
                        height: circle,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primaryContainer.withValues(alpha: 0.7),
                              AppColors.secondaryContainer.withValues(alpha: 0.4),
                              AppColors.tertiaryContainer.withValues(alpha: 0.2),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      // Glow below mascot
                      Positioned(
                        bottom: 20,
                        child: Container(
                          width: circle * 0.48,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),

                      // Floating mascot
                      FloatingWidget(
                        amplitude: 12,
                        duration: const Duration(milliseconds: 3800),
                        child: Image.asset(
                          AppAssets.mascotCapLying,
                          width: mascot,
                          height: mascot,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            AppAssets.logoBaby,
                            width: mascot * 0.95,
                            height: mascot * 0.95,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Symbols.child_care,
                              size: mascot * 0.43,
                              color: AppColors.primary,
                              fill: 1,
                            ),
                          ),
                        ),
                      ),

                      // Badge bottom-right
                      PositionedDirectional(
                        bottom: -4,
                        end: -10,
                        child: FloatingDecoration(
                          delay: const Duration(seconds: 1),
                          amplitude: 10,
                          child: Container(
                            width: badge,
                            height: badge,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.20),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Symbols.school,
                              color: AppColors.secondary,
                              size: badge * 0.47,
                              fill: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  Text(
                    'بيانور',
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
                    'BAYANOUR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
