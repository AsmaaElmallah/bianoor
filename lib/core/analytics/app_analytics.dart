import 'package:flutter/foundation.dart';

/// Lightweight analytics hook — no-op until Crashlytics/GA wired in Phase 10+.
class AppAnalytics {
  AppAnalytics._();

  static void log(String name, [Map<String, Object?>? params]) {
    if (kDebugMode) {
      debugPrint('[Analytics] $name ${params ?? {}}');
    }
    // Wire Firebase Analytics / Mixpanel here for production.
  }

  static void onboardingComplete() => log('onboarding_complete');

  static void purchaseSuccess(String planId) =>
      log('purchase_success', {'plan_id': planId});

  static void lessonComplete(String track) =>
      log('lesson_complete', {'track': track});
}
