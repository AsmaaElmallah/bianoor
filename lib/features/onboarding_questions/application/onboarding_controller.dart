import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/baby_profile_model.dart';

class OnboardingController extends StateNotifier<BabyProfile> {
  OnboardingController() : super(const BabyProfile());

  void setName(String value) => state = state.copyWith(name: value);
  void setGender(BabyGender value) => state = state.copyWith(gender: value);
  void setAgeRange(BabyAgeRange value) => state = state.copyWith(ageRange: value);
  void setStrengths(String value) => state = state.copyWith(strengths: value);
  void setChallenges(String value) => state = state.copyWith(challenges: value);
  void setHasSpecialNeeds(bool value) => state = state.copyWith(hasSpecialNeeds: value);
  void setSpecialNeedsDetails(String value) =>
      state = state.copyWith(specialNeedsDetails: value);
  void setNutrition(NutritionType value) => state = state.copyWith(nutrition: value);
  void setHasPhysicalActivity(bool value) =>
      state = state.copyWith(hasPhysicalActivity: value);
  void setSleepPattern(SleepPattern value) =>
      state = state.copyWith(sleepPattern: value);
  void toggleSleepIssue(SleepIssue issue) {
    final next = Set<SleepIssue>.from(state.sleepIssues);
    if (next.contains(issue)) {
      next.remove(issue);
    } else {
      next.add(issue);
    }
    state = state.copyWith(sleepIssues: next);
  }

  void setBehaviorNotes(String value) =>
      state = state.copyWith(behaviorNotes: value);

  bool get isValid => state.name.trim().isNotEmpty;
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, BabyProfile>((ref) {
  return OnboardingController();
});
