import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/baby_profile_model.dart';

final onboardingCloudRepositoryProvider =
    Provider<OnboardingCloudRepository>((ref) {
  return OnboardingCloudRepository();
});

class OnboardingCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Map<String, dynamic> profileToJson(BabyProfile p) {
    return {
      'name': p.name,
      'gender': p.gender.name,
      'age_range': p.ageRange.name,
      'age_range_index': BabyAgeRange.values.indexOf(p.ageRange),
      'strengths': p.strengths,
      'challenges': p.challenges,
      'has_special_needs': p.hasSpecialNeeds,
      'special_needs_details': p.specialNeedsDetails,
      'nutrition': p.nutrition.name,
      'has_physical_activity': p.hasPhysicalActivity,
      'sleep_pattern': p.sleepPattern.name,
      'sleep_issues': p.sleepIssues.map((e) => e.name).toList(),
      'behavior_notes': p.behaviorNotes,
    };
  }

  Future<bool> saveAnswers({
    required BabyProfile profile,
    String? childId,
  }) async {
    if (!await _ready()) return false;
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await SupabaseBootstrap.client.from('onboarding_answers').upsert(
        {
          'user_id': userId,
          'child_id': childId,
          'answers': profileToJson(profile),
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,child_id',
      );
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Onboarding] save failed: $e\n$st');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchAnswers({String? childId}) async {
    if (!await _ready()) return null;
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      var q = SupabaseBootstrap.client
          .from('onboarding_answers')
          .select()
          .eq('user_id', userId);
      if (childId != null) {
        q = q.eq('child_id', childId);
      }
      return await q.order('updated_at', ascending: false).limit(1).maybeSingle();
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Onboarding] fetch failed: $e\n$st');
      return null;
    }
  }
}
