import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session_provider.dart';
import '../config/supabase_config.dart';
import '../storage/prefs_service.dart';
import 'app_routes.dart';

/// مسارات لا تتطلب تسجيل دخول (حتى مع Supabase).
const _publicPaths = {
  AppRoutes.splash,
  AppRoutes.videoIntro,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.devTools,
};

/// مسارات الإعداد بعد التسجيل.
const _onboardingPaths = {
  AppRoutes.language,
  AppRoutes.rules,
  AppRoutes.subscription,
  AppRoutes.onboardingQuestions,
  AppRoutes.onboardingSurvey,
  AppRoutes.nutrition,
  AppRoutes.sleep,
  AppRoutes.skills,
};

bool _isUnder(String location, String base) {
  if (location == base) return true;
  return location.startsWith('$base/');
}

String? resolveAppRedirect(GoRouterState state, Ref ref) {
  final location = state.matchedLocation;
  final prefs = ref.read(prefsServiceProvider);

  if (!SupabaseConfig.isConfigured) {
    return null;
  }

  final auth = ref.read(authSessionProvider).valueOrNull;
  final isLoggedIn = auth?.isLoggedIn ?? prefs.isAuthenticated();
  final onboardingDone = prefs.isOnboardingComplete();

  final isPublic = _publicPaths.contains(location) ||
      location.startsWith('${AppRoutes.devTools}/');
  final isOnboarding = _onboardingPaths.contains(location);
  final isAuthScreen = location == AppRoutes.login || location == AppRoutes.signup;

  if (!isLoggedIn) {
    if (isPublic || isOnboarding) return null;
    return AppRoutes.login;
  }

  if (isAuthScreen) {
    return onboardingDone ? AppRoutes.home : AppRoutes.language;
  }

  if (_isUnder(location, AppRoutes.home) && !onboardingDone) {
    return AppRoutes.language;
  }

  return null;
}
