import '../../onboarding_questions/domain/baby_profile_model.dart';
import 'quran_progress.dart';

/// Half-hizb segments per full Quran khatmah (60 hizbs × 2).
const int quranSessionsPerKhatmah = 120;

/// Target khatmah count by age 2 years.
const int quranTargetKhatmahCount = 50;

/// Typical half-hizb listening length (minutes) for UI hints.
const int quranHalfHizbDurationMinutes = 15;

/// Listening sessions per day, by current khatmah index.
int dailySessionsForKhatmah(int khatmahIndex) {
  if (khatmahIndex <= 1) return 2;
  if (khatmahIndex == 2) return 3;
  if (khatmahIndex == 3) return 4;
  return 5;
}

/// Calendar days to finish one khatmah at the plan above.
int daysPerKhatmahForIndex(int khatmahIndex) =>
    quranSessionsPerKhatmah ~/ dailySessionsForKhatmah(khatmahIndex);

/// Parent hizb (1–60) for a half-hizb session index (1–120).
int parentHizbForSession(int sessionIndex) => (sessionIndex + 1) ~/ 2;

/// 1 = first half, 2 = second half of the parent hizb.
int halfOfHizbForSession(int sessionIndex) => sessionIndex.isOdd ? 1 : 2;

String halfHizbSessionTitle(int sessionIndex) {
  final hizb = parentHizbForSession(sessionIndex);
  final half = halfOfHizbForSession(sessionIndex);
  return 'نصف حزب $hizb (${half == 1 ? 'الأول' : 'الثاني'})';
}

/// Approximate age in months from onboarding age range until birth date is stored.
int approximateMonthsFromAgeRange(BabyAgeRange range) {
  switch (range) {
    case BabyAgeRange.age0to3:
      return 1;
    case BabyAgeRange.age3to6:
      return 4;
    case BabyAgeRange.age6to12:
      return 9;
    case BabyAgeRange.age1to1_5:
      return 15;
    case BabyAgeRange.age1_5to2:
      return 21;
  }
}

int babyAgeRangeToIndex(BabyAgeRange range) => BabyAgeRange.values.indexOf(range);

BabyAgeRange babyAgeRangeFromIndex(int index) {
  final values = BabyAgeRange.values;
  if (index < 0 || index >= values.length) return BabyAgeRange.age0to3;
  return values[index];
}

/// Listening sessions finished inside a given khatmah (0–120).
int completedSessionsForKhatmah(QuranProgress progress, int khatmahIndex) {
  if (khatmahIndex < progress.currentKhatmahIndex) {
    return quranSessionsPerKhatmah;
  }
  if (khatmahIndex > progress.currentKhatmahIndex) {
    return 0;
  }
  return progress.currentSessionIndex - 1;
}

bool isKhatmahFullyComplete(QuranProgress progress, int khatmahIndex) =>
    khatmahIndex < progress.currentKhatmahIndex;

int completedDaysForKhatmah(QuranProgress progress, int khatmahIndex) {
  final daily = dailySessionsForKhatmah(khatmahIndex);
  return completedSessionsForKhatmah(progress, khatmahIndex) ~/ daily;
}

int currentDayForKhatmah(QuranProgress progress, int khatmahIndex) {
  final totalDays = daysPerKhatmahForIndex(khatmahIndex);
  final completedDays = completedDaysForKhatmah(progress, khatmahIndex);
  if (completedDays >= totalDays) return totalDays;
  return completedDays + 1;
}

int sessionsDoneOnCurrentDay(QuranProgress progress, int khatmahIndex) {
  final daily = dailySessionsForKhatmah(khatmahIndex);
  return completedSessionsForKhatmah(progress, khatmahIndex) % daily;
}

int remainingDaysForKhatmah(QuranProgress progress, int khatmahIndex) {
  final total = daysPerKhatmahForIndex(khatmahIndex);
  return (total - completedDaysForKhatmah(progress, khatmahIndex)).clamp(0, total);
}

String quranDayLabel(int dayIndex) {
  if (dayIndex < 1 || dayIndex > _arabicDayOrdinals.length) {
    return 'اليوم $dayIndex';
  }
  return 'اليوم ${_arabicDayOrdinals[dayIndex - 1]}';
}

const _arabicDayOrdinals = <String>[
  'الأول',
  'الثاني',
  'الثالث',
  'الرابع',
  'الخامس',
  'السادس',
  'السابع',
  'الثامن',
  'التاسع',
  'العاشر',
  'الحادي عشر',
  'الثاني عشر',
  'الثالث عشر',
  'الرابع عشر',
  'الخامس عشر',
  'السادس عشر',
  'السابع عشر',
  'الثامن عشر',
  'التاسع عشر',
  'العشرون',
  'الحادي والعشرون',
  'الثاني والعشرون',
  'الثالث والعشرون',
  'الرابع والعشرون',
  'الخامس والعشرون',
  'السادس والعشرون',
  'السابع والعشرون',
  'الثامن والعشرون',
  'التاسع والعشرون',
  'الثلاثون',
  'الحادي والثلاثون',
  'الثاني والثلاثون',
  'الثالث والثلاثون',
  'الرابع والثلاثون',
  'الخامس والثلاثون',
  'السادس والثلاثون',
  'السابع والثلاثون',
  'الثامن والثلاثون',
  'التاسع والثلاثون',
  'الأربعون',
  'الحادي والأربعون',
  'الثاني والأربعون',
  'الثالث والأربعون',
  'الرابع والأربعون',
  'الخامس والأربعون',
  'السادس والأربعون',
  'السابع والأربعون',
  'الثامن والأربعون',
  'التاسع والأربعون',
  'الخمسون',
  'الحادي والخمسون',
  'الثاني والخمسون',
  'الثالث والخمسون',
  'الرابع والخمسون',
  'الخامس والخمسون',
  'السادس والخمسون',
  'السابع والخمسون',
  'الثامن والخمسون',
  'التاسع والخمسون',
  'الستون',
];
