import 'curriculum_shared_schedule.dart';

/// قواعد الجلسات ومدة التركيز اليومية (مشتركة بين المواد).
class CurriculumDayRules {
  const CurriculumDayRules({
    required this.repetitionsPerDay,
    required this.focusMinSec,
    required this.focusMaxSec,
    required this.isTrainingDay,
  });

  final int repetitionsPerDay;
  final int focusMinSec;
  final int focusMaxSec;
  final bool isTrainingDay;
}

CurriculumDayRules curriculumRulesForDay(
  int day, {
  required int lastNewContentDay,
}) {
  if (!curriculumIsTrainingDay(day)) {
    return const CurriculumDayRules(
      repetitionsPerDay: 0,
      focusMinSec: 0,
      focusMaxSec: 0,
      isTrainingDay: false,
    );
  }

  if (day <= 25) {
    return const CurriculumDayRules(
      repetitionsPerDay: 2,
      focusMinSec: 3,
      focusMaxSec: 8,
      isTrainingDay: true,
    );
  }
  if (day <= 42) {
    return const CurriculumDayRules(
      repetitionsPerDay: 3,
      focusMinSec: 8,
      focusMaxSec: 15,
      isTrainingDay: true,
    );
  }
  if (day <= 50) {
    return const CurriculumDayRules(
      repetitionsPerDay: 4,
      focusMinSec: 10,
      focusMaxSec: 30,
      isTrainingDay: true,
    );
  }
  if (day <= 55) {
    return const CurriculumDayRules(
      repetitionsPerDay: 5,
      focusMinSec: 10,
      focusMaxSec: 30,
      isTrainingDay: true,
    );
  }
  if (day <= 90) {
    return const CurriculumDayRules(
      repetitionsPerDay: 5,
      focusMinSec: 60,
      focusMaxSec: 90,
      isTrainingDay: true,
    );
  }
  if (day <= lastNewContentDay) {
    return const CurriculumDayRules(
      repetitionsPerDay: 5,
      focusMinSec: 10,
      focusMaxSec: 60,
      isTrainingDay: true,
    );
  }
  return const CurriculumDayRules(
    repetitionsPerDay: 5,
    focusMinSec: 60,
    focusMaxSec: 480,
    isTrainingDay: true,
  );
}
