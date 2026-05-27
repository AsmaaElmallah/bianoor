import 'curriculum_shared_schedule.dart';

/// نطاق أيام المنهج لدرس واحد (مرحلة المحتوى الجديد).
class CurriculumLessonDaySpan {
  const CurriculumLessonDaySpan({
    required this.lessonNumber,
    required this.startDay,
    required this.endDay,
  });

  final int lessonNumber;
  final int startDay;
  final int endDay;

  int get dayCount => endDay - startDay + 1;
}

/// أول/آخر يوم منهج لدرس [lessonNumber] (١…[maxLessonNumber]).
CurriculumLessonDaySpan curriculumLessonDaySpan(
  int lessonNumber, {
  required int maxLessonNumber,
}) {
  final lesson = lessonNumber.clamp(1, maxLessonNumber);
  if (lesson == 1) {
    return const CurriculumLessonDaySpan(lessonNumber: 1, startDay: 1, endDay: 25);
  }
  if (lesson == 2) {
    return const CurriculumLessonDaySpan(lessonNumber: 2, startDay: 26, endDay: 42);
  }
  if (lesson == 3) {
    return const CurriculumLessonDaySpan(lessonNumber: 3, startDay: 43, endDay: 50);
  }
  if (lesson == 4) {
    return const CurriculumLessonDaySpan(lessonNumber: 4, startDay: 51, endDay: 55);
  }
  final start = 56 + (lesson - 5) * 5;
  return CurriculumLessonDaySpan(
    lessonNumber: lesson,
    startDay: start,
    endDay: start + 4,
  );
}

int curriculumCurrentLessonNumber(
  int curriculumDay, {
  required int lastNewContentDay,
  required int maxLessonNumber,
  required int reviewCycleStartDay,
}) =>
    curriculumLessonNumberForDay(
      curriculumDay,
      lastNewContentDay: lastNewContentDay,
      maxLessonNumber: maxLessonNumber,
      reviewCycleStartDay: reviewCycleStartDay,
    );

bool curriculumIsLessonLocked(
  int lessonNumber,
  int curriculumDay, {
  required int lastNewContentDay,
  required int maxLessonNumber,
  required int reviewCycleStartDay,
  bool unlockAllLessons = false,
}) {
  if (unlockAllLessons) return false;
  if (curriculumDay > lastNewContentDay) return false;
  return lessonNumber >
      curriculumCurrentLessonNumber(
        curriculumDay,
        lastNewContentDay: lastNewContentDay,
        maxLessonNumber: maxLessonNumber,
        reviewCycleStartDay: reviewCycleStartDay,
      );
}

bool curriculumIsLessonFullyComplete(
  int lessonNumber,
  int curriculumDay, {
  required int maxLessonNumber,
}) {
  final span = curriculumLessonDaySpan(lessonNumber, maxLessonNumber: maxLessonNumber);
  return curriculumDay > span.endDay;
}

int curriculumCompletedDaysInLesson(
  int lessonNumber,
  int curriculumDay, {
  required int maxLessonNumber,
}) {
  final span = curriculumLessonDaySpan(lessonNumber, maxLessonNumber: maxLessonNumber);
  if (curriculumDay < span.startDay) return 0;
  if (curriculumDay > span.endDay) return span.dayCount;
  return curriculumDay - span.startDay;
}

int curriculumCurrentDayIndexInLesson(
  int lessonNumber,
  int curriculumDay, {
  required int maxLessonNumber,
}) {
  final span = curriculumLessonDaySpan(lessonNumber, maxLessonNumber: maxLessonNumber);
  if (curriculumDay < span.startDay) return 1;
  if (curriculumDay > span.endDay) return span.dayCount;
  return curriculumDay - span.startDay + 1;
}

int curriculumRemainingDaysInLesson(
  int lessonNumber,
  int curriculumDay, {
  required int maxLessonNumber,
}) {
  final span = curriculumLessonDaySpan(lessonNumber, maxLessonNumber: maxLessonNumber);
  final total = span.dayCount;
  return (total - curriculumCompletedDaysInLesson(
        lessonNumber,
        curriculumDay,
        maxLessonNumber: maxLessonNumber,
      ))
      .clamp(0, total);
}

/// تسمية يوم داخل الدرس (١ = اليوم الأول داخل الدرس).
String curriculumLessonDayLabel(int dayIndexInLesson) {
  const ordinals = <String>[
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
  ];
  if (dayIndexInLesson < 1 || dayIndexInLesson > ordinals.length) {
    return 'اليوم $dayIndexInLesson';
  }
  return 'اليوم ${ordinals[dayIndexInLesson - 1]}';
}
