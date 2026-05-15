import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/feature_placeholder_screen.dart';
import '../../features/home/presentation/home_shell_screen.dart';
import '../../features/language/presentation/language_screen.dart';
import '../../features/onboarding_questions/presentation/child_info_screen.dart';
import '../../features/onboarding_questions/presentation/nutrition_screen.dart';
import '../../features/onboarding_questions/presentation/onboarding_survey_screen.dart';
import '../../features/onboarding_questions/presentation/skills_screen.dart';
import '../../features/onboarding_questions/presentation/sleep_screen.dart';
import '../../features/onboarding_video/presentation/video_intro_screen.dart';
import '../../features/quran/presentation/quran_journey_screen.dart';
import '../../features/quran/domain/quran_age_schedule.dart';
import '../../features/quran/presentation/quran_khatmah_days_screen.dart';
import '../../features/quran/presentation/quran_khatmah_celebration_screen.dart';
import '../../features/quran/presentation/quran_lesson_screen.dart';
import '../../features/quran/presentation/quran_player_screen.dart';
import '../../features/rules/presentation/family_rules_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.videoIntro,
        builder: (context, state) => const VideoIntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.rules,
        builder: (context, state) => const FamilyRulesScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingQuestions,
        builder: (context, state) => const ChildInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingSurvey,
        builder: (context, state) => const OnboardingSurveyScreen(),
      ),
      GoRoute(
        path: AppRoutes.nutrition,
        builder: (context, state) => const NutritionScreen(),
      ),
      GoRoute(
        path: AppRoutes.sleep,
        builder: (context, state) => const SleepScreen(),
      ),
      GoRoute(
        path: AppRoutes.skills,
        builder: (context, state) => const SkillsScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShellScreen(),
        routes: [
          GoRoute(
            path: 'feature/:id',
            builder: (context, state) => FeaturePlaceholderScreen(
              featureId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'quran',
            builder: (context, state) => const QuranLessonScreen(),
            routes: [
              GoRoute(
                path: 'player',
                builder: (context, state) => const QuranPlayerScreen(),
              ),
              GoRoute(
                path: 'journey',
                builder: (context, state) => const QuranJourneyScreen(),
                routes: [
                  GoRoute(
                    path: ':khatmahIndex',
                    builder: (context, state) {
                      final index =
                          int.tryParse(state.pathParameters['khatmahIndex'] ?? '') ?? 1;
                      return QuranKhatmahDaysScreen(
                        khatmahIndex: index.clamp(1, quranTargetKhatmahCount),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'celebration/:khatmahIndex',
                builder: (context, state) {
                  final index = int.tryParse(state.pathParameters['khatmahIndex'] ?? '') ?? 1;
                  return QuranKhatmahCelebrationScreen(completedKhatmahIndex: index);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});
