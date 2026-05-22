import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/feature_placeholder_screen.dart';
import '../../features/home/presentation/home_shell_screen.dart';
import '../../features/activities/presentation/activities_age_groups_screen.dart';
import '../../features/activities/presentation/activities_hub_screen.dart';
import '../../features/exercises/presentation/exercises_age_groups_screen.dart';
import '../../features/exercises/presentation/exercises_hub_screen.dart';
import '../../features/library/presentation/library_media_hub_screen.dart';
import '../../features/library/presentation/library_media_list_screen.dart';
import '../../features/library/presentation/library_media_player_screen.dart';
import '../../features/language/presentation/language_screen.dart';
import '../../features/onboarding_questions/presentation/child_info_screen.dart';
import '../../features/onboarding_questions/presentation/nutrition_screen.dart';
import '../../features/onboarding_questions/presentation/onboarding_survey_screen.dart';
import '../../features/onboarding_questions/presentation/skills_screen.dart';
import '../../features/onboarding_questions/presentation/sleep_screen.dart';
import '../../features/onboarding_video/presentation/video_intro_screen.dart';
import '../../features/math/presentation/math_journey_screen.dart';
import '../../features/math/presentation/math_lesson_days_screen.dart';
import '../../features/math/presentation/math_player_screen.dart';
import '../../features/math/presentation/math_roadmap_screen.dart';
import '../../features/visual/presentation/visual_journey_screen.dart';
import '../../features/visual/presentation/visual_lesson_days_screen.dart';
import '../../features/visual/presentation/visual_player_screen.dart';
import '../../features/visual/presentation/visual_roadmap_screen.dart';
import '../../features/emotional/presentation/emotional_journey_screen.dart';
import '../../features/emotional/presentation/emotional_lesson_days_screen.dart';
import '../../features/emotional/presentation/emotional_player_screen.dart';
import '../../features/emotional/presentation/emotional_roadmap_screen.dart';
import '../../features/visual/domain/visual_curriculum_schedule.dart';
import '../../features/emotional/domain/emotional_curriculum_schedule.dart';
import '../../features/quran/presentation/quran_journey_screen.dart';
import '../../features/quran/domain/quran_age_schedule.dart';
import '../../features/quran/presentation/quran_khatmah_days_screen.dart';
import '../../features/quran/presentation/quran_khatmah_celebration_screen.dart';
import '../../features/quran/presentation/quran_player_screen.dart';
import '../../features/rules/presentation/family_rules_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import 'app_routes.dart';

/// يعرض شاشات الدروس فوق الرئيسية (مثل القرآن) وليس داخل شجرة /home المخفية.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
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
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => FeaturePlaceholderScreen(
              featureId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'library/:categoryId',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => LibraryMediaHubScreen(
              categoryId: state.pathParameters['categoryId']!,
            ),
            routes: [
              GoRoute(
                path: 'watch',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final q = state.uri.queryParameters;
                  final rawTitle = q['title'];
                  return LibraryMediaPlayerScreen(
                    title: rawTitle != null
                        ? Uri.decodeComponent(rawTitle)
                        : 'تشغيل',
                    videoId: q['v'],
                    playlistId: q['list'],
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'exercises',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const ExercisesAgeGroupsScreen(),
            routes: [
              GoRoute(
                path: ':ageGroupId',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => ExercisesHubScreen(
                  ageGroupId: state.pathParameters['ageGroupId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'activities',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const ActivitiesAgeGroupsScreen(),
            routes: [
              GoRoute(
                path: ':ageGroupId',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => ActivitiesHubScreen(
                  ageGroupId: state.pathParameters['ageGroupId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'math',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const MathJourneyScreen(),
            routes: [
              GoRoute(
                path: 'player',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const MathPlayerScreen(),
              ),
              GoRoute(
                path: 'roadmap',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const MathRoadmapScreen(),
              ),
              GoRoute(
                path: ':lessonIndex',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final index =
                      int.tryParse(state.pathParameters['lessonIndex'] ?? '') ?? 1;
                  return MathLessonDaysScreen(
                    lessonNumber: index.clamp(1, 25),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'visual',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const VisualJourneyScreen(),
            routes: [
              GoRoute(
                path: 'player',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const VisualPlayerScreen(),
              ),
              GoRoute(
                path: 'roadmap',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const VisualRoadmapScreen(),
              ),
              GoRoute(
                path: ':lessonIndex',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final index =
                      int.tryParse(state.pathParameters['lessonIndex'] ?? '') ?? 1;
                  return VisualLessonDaysScreen(
                    lessonNumber: index.clamp(1, visualLessonCount),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'emotional',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const EmotionalJourneyScreen(),
            routes: [
              GoRoute(
                path: 'player',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const EmotionalPlayerScreen(),
              ),
              GoRoute(
                path: 'roadmap',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const EmotionalRoadmapScreen(),
              ),
              GoRoute(
                path: ':lessonIndex',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final index =
                      int.tryParse(state.pathParameters['lessonIndex'] ?? '') ?? 1;
                  return EmotionalLessonDaysScreen(
                    lessonNumber: index.clamp(1, emotionalLessonCount),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'quran',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const QuranJourneyScreen(),
            routes: [
              GoRoute(
                path: 'player',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const QuranPlayerScreen(),
              ),
              GoRoute(
                path: 'celebration/:khatmahIndex',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final index = int.tryParse(state.pathParameters['khatmahIndex'] ?? '') ?? 1;
                  return QuranKhatmahCelebrationScreen(completedKhatmahIndex: index);
                },
              ),
              GoRoute(
                path: ':khatmahIndex',
                parentNavigatorKey: rootNavigatorKey,
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
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
