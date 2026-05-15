import 'package:flutter/foundation.dart';

enum BabyGender { male, female }

enum BabyAgeRange { age0to3, age3to6, age6to12, age1to1_5, age1_5to2 }

extension BabyAgeRangeLabel on BabyAgeRange {
  String get label {
    switch (this) {
      case BabyAgeRange.age0to3:
        return '0-3 شهور';
      case BabyAgeRange.age3to6:
        return '3-6 شهور';
      case BabyAgeRange.age6to12:
        return '6-12 شهر';
      case BabyAgeRange.age1to1_5:
        return '1-1.5 سنة';
      case BabyAgeRange.age1_5to2:
        return '1.5-2 سنة';
    }
  }
}

enum NutritionType { breastfeeding, formula, balanced, irregular }

extension NutritionTypeLabel on NutritionType {
  String get label {
    switch (this) {
      case NutritionType.breastfeeding:
        return 'رضاعة طبيعية';
      case NutritionType.formula:
        return 'حليب صناعي';
      case NutritionType.balanced:
        return 'نظام متوازن';
      case NutritionType.irregular:
        return 'نظام غير منتظم';
    }
  }
}

enum SleepPattern { regular, irregular }

enum SleepIssue { intermittent, continuousCrying }

extension SleepIssueLabel on SleepIssue {
  String get title {
    switch (this) {
      case SleepIssue.intermittent:
        return 'نوم متقطع';
      case SleepIssue.continuousCrying:
        return 'بكاء مستمر';
    }
  }

  String get subtitle {
    switch (this) {
      case SleepIssue.intermittent:
        return 'الاستيقاظ المتكرر خلال الليل';
      case SleepIssue.continuousCrying:
        return 'صعوبة في التهدئة قبل أو بعد النوم';
    }
  }
}

@immutable
class BabyProfile {
  const BabyProfile({
    this.name = '',
    this.gender = BabyGender.male,
    this.ageRange = BabyAgeRange.age0to3,
    this.strengths = '',
    this.challenges = '',
    this.hasSpecialNeeds = false,
    this.specialNeedsDetails = '',
    this.nutrition = NutritionType.breastfeeding,
    this.hasPhysicalActivity = true,
    this.sleepPattern = SleepPattern.regular,
    this.sleepIssues = const <SleepIssue>{},
    this.behaviorNotes = '',
  });

  final String name;
  final BabyGender gender;
  final BabyAgeRange ageRange;
  final String strengths;
  final String challenges;
  final bool hasSpecialNeeds;
  final String specialNeedsDetails;
  final NutritionType nutrition;
  final bool hasPhysicalActivity;
  final SleepPattern sleepPattern;
  final Set<SleepIssue> sleepIssues;
  final String behaviorNotes;

  BabyProfile copyWith({
    String? name,
    BabyGender? gender,
    BabyAgeRange? ageRange,
    String? strengths,
    String? challenges,
    bool? hasSpecialNeeds,
    String? specialNeedsDetails,
    NutritionType? nutrition,
    bool? hasPhysicalActivity,
    SleepPattern? sleepPattern,
    Set<SleepIssue>? sleepIssues,
    String? behaviorNotes,
  }) {
    return BabyProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      strengths: strengths ?? this.strengths,
      challenges: challenges ?? this.challenges,
      hasSpecialNeeds: hasSpecialNeeds ?? this.hasSpecialNeeds,
      specialNeedsDetails: specialNeedsDetails ?? this.specialNeedsDetails,
      nutrition: nutrition ?? this.nutrition,
      hasPhysicalActivity: hasPhysicalActivity ?? this.hasPhysicalActivity,
      sleepPattern: sleepPattern ?? this.sleepPattern,
      sleepIssues: sleepIssues ?? this.sleepIssues,
      behaviorNotes: behaviorNotes ?? this.behaviorNotes,
    );
  }
}
