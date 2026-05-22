import 'math_track.dart';

/// مرجع شريحة واحدة داخل التسلسل العالمي (٣ بوربوينت بالترتيب).
class MathSlideRef {
  const MathSlideRef({required this.packageId, required this.slideIndex});

  final String packageId;
  final int slideIndex;
}

/// نطاق شرائح درس واحد (تسلسل عالمي ١-based).
class MathLessonSlideRange {
  const MathLessonSlideRange({
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

/// أعمدة ملف CSV: نطاقات الشرائح داخل كل بوربوينت.
class MathLessonPptColumns {
  const MathLessonPptColumns({
    required this.ppt129_132,
    required this.ppt133_136,
    required this.pptBeads,
  });

  final String ppt129_132;
  final String ppt133_136;
  final String pptBeads;
}

/// أقصى شرائح ملف 133-136 في التسلسل (١٠٠ حسب المنهج؛ المانيفست قد يحتوي ١٠١).
const mathDotNumericSequenceCap = 100;

/// إجمالي الشرائح المتوقع في التسلسل: ١٠٠ + ١٠٠ + ٣٧ = ٢٣٧.
const mathExpectedGlobalSlideCount = 237;

/// آخر يوم بمحتوى جديد (كل الشرائح ٢٣٧ لأول مرة).
const mathLastNewContentDay = 160;

/// مدة البرنامج بالأيام (سنتان).
const mathCurriculumTotalDays = 730;

/// أول يوم تدوير الدروس ١–٢٥ (٥ أيام/درس، ٥ جلسات).
const mathReviewCycleStartDay = 161;

/// رقم الدرس النشط ليوم المنهج (١–٢٥).
int mathLessonNumberForDay(int day) {
  final d = day < 1 ? 1 : day;
  if (d <= 25) return 1;
  if (d <= 42) return 2;
  if (d <= 50) return 3;
  if (d <= 55) return 4;
  if (d <= mathLastNewContentDay) return 5 + ((d - 56) ~/ 5);
  return 1 + ((d - mathReviewCycleStartDay) ~/ 5) % 25;
}

/// هل اليوم يوم تدريب (يوجد فيه جلسات)؟
bool mathIsTrainingDay(int day) => true;

/// شرائح الدرس [lessonNumber] ضمن التسلسل العالمي.
MathLessonSlideRange mathLessonSlideRange(int lessonNumber) {
  final lesson = lessonNumber.clamp(1, 25);
  if (lesson == 1) {
    return const MathLessonSlideRange(
      lessonNumber: 1,
      slideCount: 5,
      globalStart: 1,
      globalEnd: 5,
    );
  }
  if (lesson == 11) {
    return const MathLessonSlideRange(
      lessonNumber: 11,
      slideCount: 5,
      globalStart: 96,
      globalEnd: 100,
    );
  }
  if (lesson == 25) {
    return const MathLessonSlideRange(
      lessonNumber: 25,
      slideCount: 7,
      globalStart: 231,
      globalEnd: 237,
    );
  }
  if (lesson >= 2 && lesson <= 10) {
    final start = 6 + 10 * (lesson - 2);
    return MathLessonSlideRange(
      lessonNumber: lesson,
      slideCount: 10,
      globalStart: start,
      globalEnd: start + 9,
    );
  }
  // ١٢–٢٤
  final start = 101 + 10 * (lesson - 12);
  return MathLessonSlideRange(
    lessonNumber: lesson,
    slideCount: 10,
    globalStart: start,
    globalEnd: start + 9,
  );
}

MathLessonSlideRange mathLessonSlideRangeForDay(int day) {
  return mathLessonSlideRange(mathLessonNumberForDay(day));
}

/// نطاقات أعمدة البوربوينت لصف CSV (مثلاً `96-100` أو `-`).
MathLessonPptColumns mathPptColumnsForGlobalRange(int globalFrom, int globalTo) {
  var ppt129 = '-';
  var ppt133 = '-';
  var beads = '-';

  if (globalFrom <= 100) {
    final end = globalTo > 100 ? 100 : globalTo;
    if (globalFrom <= end) ppt129 = '$globalFrom-$end';
  }
  if (globalTo > 100) {
    final from = globalFrom > 100 ? globalFrom - 100 : 1;
    final end = globalTo > 200 ? 100 : globalTo - 100;
    if (from <= end) ppt133 = '$from-$end';
  }
  if (globalTo > 200) {
    final from = globalFrom > 200 ? globalFrom - 200 : 1;
    final end = globalTo - 200;
    if (from <= end) beads = '$from-$end';
  }

  return MathLessonPptColumns(
    ppt129_132: ppt129,
    ppt133_136: ppt133,
    pptBeads: beads,
  );
}

MathLessonPptColumns mathPptColumnsForLesson(int lessonNumber) {
  final r = mathLessonSlideRange(lessonNumber);
  return mathPptColumnsForGlobalRange(r.globalStart, r.globalEnd);
}

/// مرحلة المنهج (للتوثيق في CSV).
String mathPhaseCodeForDay(int day) {
  if (day <= 25) return 'A';
  if (day <= 42) return 'B';
  if (day <= 50) return 'C';
  if (day <= 55) return 'D';
  if (day <= 60) return 'E';
  if (day <= 90) return 'F';
  if (day <= mathLastNewContentDay) return 'G';
  return 'R';
}

/// يبني التسلسل العالمي من حزم المانيفست الثلاث.
List<MathSlideRef> buildMathGlobalSlideSequence({
  required int ppt129SlideCount,
  required int ppt133SlideCount,
  required int beadsSlideCount,
}) {
  final refs = <MathSlideRef>[];
  void addPackage(String id, int count) {
    for (var i = 1; i <= count; i++) {
      refs.add(MathSlideRef(packageId: id, slideIndex: i));
    }
  }

  addPackage(mathCorePackageIds[0], ppt129SlideCount);
  addPackage(
    mathCorePackageIds[1],
    ppt133SlideCount > mathDotNumericSequenceCap
        ? mathDotNumericSequenceCap
        : ppt133SlideCount,
  );
  addPackage(mathCorePackageIds[2], beadsSlideCount);
  return refs;
}
