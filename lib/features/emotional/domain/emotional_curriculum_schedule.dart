import '../../curriculum/domain/curriculum_shared_schedule.dart';

class EmotionalSlideRef {
  const EmotionalSlideRef({required this.packageId, required this.slideIndex});

  final String packageId;
  final int slideIndex;
}

class EmotionalLessonSlideRange {
  const EmotionalLessonSlideRange({
    required this.lessonNumber,
    required this.slideCount,
    required this.globalStart,
    required this.globalEnd,
  });

  final int lessonNumber;
  final int slideCount;
  final int globalStart;
  final int globalEnd;
}

/// ترتيب ملفات PPTX المصدر (٣٢ حزمة → ١٦٢ شريحة).
List<String> get emotionalSourcePackageIds => List.generate(
      32,
      (i) => 'emotional_src_${(i + 1).toString().padLeft(2, '0')}',
    );

const emotionalExpectedGlobalSlideCount = 162;
const emotionalLessonCount = 17;
const emotionalLastNewContentDay = 120;
const emotionalReviewCycleStartDay = 121;

int emotionalLessonNumberForDay(int day) => curriculumLessonNumberForDay(
      day,
      lastNewContentDay: emotionalLastNewContentDay,
      maxLessonNumber: emotionalLessonCount,
      reviewCycleStartDay: emotionalReviewCycleStartDay,
    );

/// شرائح الدرس: ١ = ٥، ٢–١٦ = ١٠، ١٧ = ٧.
EmotionalLessonSlideRange emotionalLessonSlideRange(int lessonNumber) {
  final lesson = lessonNumber.clamp(1, emotionalLessonCount);
  if (lesson == 1) {
    return const EmotionalLessonSlideRange(
      lessonNumber: 1,
      slideCount: 5,
      globalStart: 1,
      globalEnd: 5,
    );
  }
  if (lesson == emotionalLessonCount) {
    return const EmotionalLessonSlideRange(
      lessonNumber: emotionalLessonCount,
      slideCount: 7,
      globalStart: 156,
      globalEnd: 162,
    );
  }
  final start = 6 + 10 * (lesson - 2);
  return EmotionalLessonSlideRange(
    lessonNumber: lesson,
    slideCount: 10,
    globalStart: start,
    globalEnd: start + 9,
  );
}

EmotionalLessonSlideRange emotionalLessonSlideRangeForDay(int day) {
  return emotionalLessonSlideRange(emotionalLessonNumberForDay(day));
}

String emotionalPhaseCodeForDay(int day) {
  if (day <= 25) return 'A';
  if (day <= 42) return 'B';
  if (day <= 50) return 'C';
  if (day <= 55) return 'D';
  if (day <= 60) return 'E';
  if (day <= 90) return 'F';
  if (day <= emotionalLastNewContentDay) return 'G';
  return 'R';
}

List<EmotionalSlideRef> buildEmotionalGlobalSlideSequence(
  Map<String, int> slideCountByPackageId,
) {
  final refs = <EmotionalSlideRef>[];
  for (final id in emotionalSourcePackageIds) {
    final count = slideCountByPackageId[id] ?? 0;
    for (var i = 1; i <= count; i++) {
      refs.add(EmotionalSlideRef(packageId: id, slideIndex: i));
    }
  }
  return refs;
}
