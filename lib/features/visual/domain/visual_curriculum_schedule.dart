import '../../curriculum/domain/curriculum_shared_schedule.dart';

class VisualSlideRef {
  const VisualSlideRef({required this.packageId, required this.slideIndex});

  final String packageId;
  final int slideIndex;
}

class VisualLessonSlideRange {
  const VisualLessonSlideRange({
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

/// ترتيب ملفات PPTX المصدر (١٨ حزمة → ٢٩٢ شريحة).
const visualSourcePackageIds = <String>[
  'visual_src_01',
  'visual_src_02',
  'visual_src_03',
  'visual_src_04',
  'visual_src_05',
  'visual_src_06',
  'visual_src_07',
  'visual_src_08',
  'visual_src_09',
  'visual_src_10',
  'visual_src_11',
  'visual_src_12',
  'visual_src_13',
  'visual_src_14',
  'visual_src_15',
  'visual_src_16',
  'visual_src_17',
  'visual_src_18',
];

const visualExpectedGlobalSlideCount = 292;
const visualLessonCount = 30;
const visualLastNewContentDay = 185;
const visualReviewCycleStartDay = 186;

int visualLessonNumberForDay(int day) => curriculumLessonNumberForDay(
      day,
      lastNewContentDay: visualLastNewContentDay,
      maxLessonNumber: visualLessonCount,
      reviewCycleStartDay: visualReviewCycleStartDay,
    );

/// شرائح الدرس: ١ = ٥، ٢–٢٩ = ١٠، ٣٠ = ٧.
VisualLessonSlideRange visualLessonSlideRange(int lessonNumber) {
  final lesson = lessonNumber.clamp(1, visualLessonCount);
  if (lesson == 1) {
    return const VisualLessonSlideRange(
      lessonNumber: 1,
      slideCount: 5,
      globalStart: 1,
      globalEnd: 5,
    );
  }
  if (lesson == visualLessonCount) {
    return const VisualLessonSlideRange(
      lessonNumber: visualLessonCount,
      slideCount: 7,
      globalStart: 286,
      globalEnd: 292,
    );
  }
  final start = 6 + 10 * (lesson - 2);
  return VisualLessonSlideRange(
    lessonNumber: lesson,
    slideCount: 10,
    globalStart: start,
    globalEnd: start + 9,
  );
}

VisualLessonSlideRange visualLessonSlideRangeForDay(int day) {
  return visualLessonSlideRange(visualLessonNumberForDay(day));
}

String visualPhaseCodeForDay(int day) {
  if (day <= 25) return 'A';
  if (day <= 42) return 'B';
  if (day <= 50) return 'C';
  if (day <= 55) return 'D';
  if (day <= 60) return 'E';
  if (day <= 90) return 'F';
  if (day <= visualLastNewContentDay) return 'G';
  return 'R';
}

List<VisualSlideRef> buildVisualGlobalSlideSequence(
  Map<String, int> slideCountByPackageId,
) {
  final refs = <VisualSlideRef>[];
  for (final id in visualSourcePackageIds) {
    final count = slideCountByPackageId[id] ?? 0;
    for (var i = 1; i <= count; i++) {
      refs.add(VisualSlideRef(packageId: id, slideIndex: i));
    }
  }
  return refs;
}
