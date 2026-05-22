/// تقويم مشترك: درس ١ (٢٥ يوم) → ٢ (١٧) → ٣ (٨) → ٤ (٥) → ٥+ (٥ أيام/درس).
const curriculumProgramTotalDays = 730;

/// رقم الدرس ليوم المنهج (المرحلة التمهيدية ثابتة؛ من ٥٦ فصاعداً ٥ أيام لكل درس).
int curriculumLessonNumberForDay(
  int day, {
  required int lastNewContentDay,
  required int maxLessonNumber,
  required int reviewCycleStartDay,
}) {
  final d = day < 1 ? 1 : day;
  if (d <= 25) return 1;
  if (d <= 42) return 2;
  if (d <= 50) return 3;
  if (d <= 55) return 4;
  if (d <= lastNewContentDay) {
    return (5 + ((d - 56) ~/ 5)).clamp(5, maxLessonNumber);
  }
  return 1 + ((d - reviewCycleStartDay) ~/ 5) % maxLessonNumber;
}

bool curriculumIsTrainingDay(int day) => true;
