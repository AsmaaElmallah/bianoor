import 'math_curriculum_schedule.dart';

/// Daily repetitions and focus duration hints by curriculum day.
class MathDayRules {
  const MathDayRules({
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

MathDayRules mathRulesForDay(int day) {
  final training = mathIsTrainingDay(day);
  if (!training) {
    return const MathDayRules(
      repetitionsPerDay: 0,
      focusMinSec: 0,
      focusMaxSec: 0,
      isTrainingDay: false,
    );
  }

  if (day <= 25) {
    return const MathDayRules(
      repetitionsPerDay: 2,
      focusMinSec: 3,
      focusMaxSec: 8,
      isTrainingDay: true,
    );
  }
  if (day <= 42) {
    return const MathDayRules(
      repetitionsPerDay: 3,
      focusMinSec: 8,
      focusMaxSec: 15,
      isTrainingDay: true,
    );
  }
  if (day <= 50) {
    return const MathDayRules(
      repetitionsPerDay: 4,
      focusMinSec: 10,
      focusMaxSec: 30,
      isTrainingDay: true,
    );
  }
  if (day <= 55) {
    return const MathDayRules(
      repetitionsPerDay: 5,
      focusMinSec: 10,
      focusMaxSec: 30,
      isTrainingDay: true,
    );
  }
  if (day <= 90) {
    return const MathDayRules(
      repetitionsPerDay: 5,
      focusMinSec: 60,
      focusMaxSec: 90,
      isTrainingDay: true,
    );
  }
  if (day <= mathLastNewContentDay) {
    return const MathDayRules(
      repetitionsPerDay: 5,
      focusMinSec: 10,
      focusMaxSec: 60,
      isTrainingDay: true,
    );
  }
  return const MathDayRules(
    repetitionsPerDay: 5,
    focusMinSec: 60,
    focusMaxSec: 480,
    isTrainingDay: true,
  );
}
