import 'package:bayanour/features/curriculum/domain/curriculum_lesson_journey.dart';
import 'package:bayanour/features/quran/domain/quran_age_schedule.dart';
import 'package:bayanour/features/subscription/data/subscription_cloud_repository.dart';
import 'package:bayanour/features/subscription/domain/subscription_plan_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Same formula as SQL `quran_session_day` in 20260526100041_freemium_lesson_days.sql.
int sqlQuranSessionDay(int khatmah, int session) {
  final before = khatmah <= 1
      ? 0
      : khatmah == 2
          ? 60
          : khatmah == 3
              ? 100
              : khatmah == 4
                  ? 130
                  : 130 + 24 * (khatmah - 4);
  final daily = khatmah <= 1
      ? 2
      : khatmah == 2
          ? 3
          : khatmah == 3
              ? 4
              : 5;
  return before + (session / daily).ceil();
}

/// Same formula as SQL `curriculum_lesson_start_day`.
int sqlLessonStartDay(int lesson) {
  if (lesson <= 1) return 1;
  if (lesson == 2) return 26;
  if (lesson == 3) return 43;
  if (lesson == 4) return 51;
  return 56 + 5 * (lesson - 5);
}

void main() {
  test('quran cumulative day matches the SQL lock', () {
    for (var k = 1; k <= 10; k++) {
      for (var s = 1; s <= 120; s++) {
        expect(quranCumulativeDay(k, s), sqlQuranSessionDay(k, s), reason: 'khatmah $k session $s');
      }
    }
    expect(quranCumulativeDay(1, 1), 1);
    expect(quranCumulativeDay(1, 60), 30);
    expect(quranCumulativeDay(1, 61), 31);
    expect(quranCumulativeDay(2, 1), 61);
  });

  test('lesson start day matches the SQL lock', () {
    for (var n = 1; n <= 40; n++) {
      expect(
        curriculumLessonDaySpan(n, maxLessonNumber: 1000).startDay,
        sqlLessonStartDay(n),
        reason: 'lesson $n',
      );
    }
  });

  test('plan savings compare against the shortest priced plan', () {
    final savings = planSavings([
      (days: 30, usd: 10),
      (days: 90, usd: 27),
      (days: 180, usd: 48),
      (days: 365, usd: null),
    ]);
    expect(savings, [null, 10, 20, null]);
  });

  test('plan savings ignore plans that cost the same or more', () {
    expect(planSavings([(days: 30, usd: 10), (days: 90, usd: 30)]), [null, null]);
    expect(planSavings([(days: 30, usd: null), (days: 90, usd: 30)]), [null, null]);
  });

  test('plan duration labels', () {
    expect(planDurationLabel(30), 'شهر');
    expect(planDurationLabel(90), '3 شهور');
    expect(planDurationLabel(180), '6 شهور');
    expect(planDurationLabel(365), 'سنة');
  });
}
