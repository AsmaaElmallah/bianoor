import 'math_track.dart';

/// كتالوج قديم لحزم إضافية داخل [manifest.json] (تصدير سابق).
/// **التشغيل الفعلي** للماث يستخدم فقط [mathCoreQuantitativePackageIds] في `math_track.dart`
/// ومنطق الجلسة في `math_curriculum_provider.dart`.
enum MathSlideMode {
  twoDaysPerSlide,
  offsetEnd,
  cumulativeTail,
  cycle,
}

class MathPackageMeta {
  const MathPackageMeta({
    required this.id,
    required this.track,
    required this.dayStart,
    required this.dayEnd,
    required this.slideMode,
  });

  final String id;
  final MathTrack track;
  final int dayStart;
  final int dayEnd;
  final MathSlideMode slideMode;

  int get daySpan => dayEnd - dayStart + 1;
}

/// ASCII package folder names under assets/math/packages/ (required for Windows Flutter builds).
const mathPackageCatalog = <MathPackageMeta>[
  MathPackageMeta(
    id: 'lesson_01_10',
    track: MathTrack.quantitative,
    dayStart: 1,
    dayEnd: 10,
    slideMode: MathSlideMode.twoDaysPerSlide,
  ),
  MathPackageMeta(
    id: 'q_11_20',
    track: MathTrack.quantitative,
    dayStart: 11,
    dayEnd: 20,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(
    id: 'lesson_20_30',
    track: MathTrack.quantitative,
    dayStart: 20,
    dayEnd: 30,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(
    id: 'lesson_30_40',
    track: MathTrack.quantitative,
    dayStart: 30,
    dayEnd: 40,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(
    id: 'lesson_41_50',
    track: MathTrack.quantitative,
    dayStart: 41,
    dayEnd: 50,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(
    id: 'lesson_51_60',
    track: MathTrack.quantitative,
    dayStart: 51,
    dayEnd: 60,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(
    id: 'lesson_61_66',
    track: MathTrack.quantitative,
    dayStart: 61,
    dayEnd: 66,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(
    id: 'lesson_67_72',
    track: MathTrack.quantitative,
    dayStart: 67,
    dayEnd: 72,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(
    id: 'lesson_73_78',
    track: MathTrack.quantitative,
    dayStart: 73,
    dayEnd: 78,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(
    id: 'lesson_79_84',
    track: MathTrack.quantitative,
    dayStart: 79,
    dayEnd: 84,
    slideMode: MathSlideMode.offsetEnd,
  ),
  MathPackageMeta(id: 'q_85_90', track: MathTrack.quantitative, dayStart: 85, dayEnd: 90, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_91_95', track: MathTrack.quantitative, dayStart: 91, dayEnd: 95, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_96_100', track: MathTrack.quantitative, dayStart: 96, dayEnd: 100, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_101_105', track: MathTrack.quantitative, dayStart: 101, dayEnd: 105, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_106_110', track: MathTrack.quantitative, dayStart: 106, dayEnd: 110, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_111_115', track: MathTrack.quantitative, dayStart: 111, dayEnd: 115, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_116_120', track: MathTrack.quantitative, dayStart: 116, dayEnd: 120, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_121_124', track: MathTrack.quantitative, dayStart: 121, dayEnd: 124, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_125_128', track: MathTrack.quantitative, dayStart: 125, dayEnd: 128, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(id: 'q_129_132', track: MathTrack.quantitative, dayStart: 129, dayEnd: 132, slideMode: MathSlideMode.cumulativeTail),
  MathPackageMeta(
    id: 'dot_numeric_133_136',
    track: MathTrack.dotNumeric,
    dayStart: 133,
    dayEnd: 136,
    slideMode: MathSlideMode.cumulativeTail,
  ),
  MathPackageMeta(
    id: 'beads_numeric',
    track: MathTrack.beadsNumeric,
    dayStart: 0,
    dayEnd: 0,
    slideMode: MathSlideMode.cycle,
  ),
];

MathPackageMeta? quantitativePackageForDay(int curriculumDay) {
  MathPackageMeta? best;
  for (final pkg in mathPackageCatalog) {
    if (pkg.track != MathTrack.quantitative) continue;
    if (curriculumDay < pkg.dayStart || curriculumDay > pkg.dayEnd) continue;
    if (best == null || pkg.dayStart > best.dayStart) {
      best = pkg;
    }
  }
  return best;
}

MathPackageMeta? packageForTrack(MathTrack track, int curriculumDay) {
  switch (track) {
    case MathTrack.quantitative:
      return quantitativePackageForDay(curriculumDay);
    case MathTrack.dotNumeric:
      if (curriculumDay < 133 || curriculumDay > 136) return null;
      return mathPackageCatalog.firstWhere((p) => p.id == 'dot_numeric_133_136');
    case MathTrack.beadsNumeric:
      return mathPackageCatalog.firstWhere((p) => p.id == 'beads_numeric');
  }
}

int resolveSlideIndex({
  required MathPackageMeta meta,
  required int curriculumDay,
  required int slideCount,
}) {
  if (slideCount <= 0) return 1;
  switch (meta.slideMode) {
    case MathSlideMode.twoDaysPerSlide:
      final idx = (curriculumDay + 1) ~/ 2;
      return idx.clamp(1, slideCount);
    case MathSlideMode.offsetEnd:
      final idx = curriculumDay + slideCount - meta.dayEnd;
      return idx.clamp(1, slideCount);
    case MathSlideMode.cumulativeTail:
      final span = meta.daySpan;
      final start = slideCount - span + 1;
      final idx = start + (curriculumDay - meta.dayStart);
      return idx.clamp(1, slideCount);
    case MathSlideMode.cycle:
      if (curriculumDay <= 0) return 1;
      return ((curriculumDay - 1) % slideCount) + 1;
  }
}

class MathSlideRange {
  const MathSlideRange({required this.start, required this.end});

  final int start;
  final int end;

  int get count => end >= start ? end - start + 1 : 0;

  Iterable<int> get indices sync* {
    for (var i = start; i <= end; i++) {
      yield i;
    }
  }
}

MathSlideRange slideRangeForSession({
  required MathPackageMeta meta,
  required int curriculumDay,
  required int slideCount,
}) {
  if (slideCount <= 0) return const MathSlideRange(start: 1, end: 0);

  switch (meta.slideMode) {
    case MathSlideMode.cycle:
      return MathSlideRange(start: 1, end: slideCount);
    case MathSlideMode.cumulativeTail:
      final segmentStart = slideCount - meta.daySpan + 1;
      final end = resolveSlideIndex(
        meta: meta,
        curriculumDay: curriculumDay,
        slideCount: slideCount,
      );
      return MathSlideRange(
        start: segmentStart.clamp(1, slideCount),
        end: end,
      );
    case MathSlideMode.twoDaysPerSlide:
    case MathSlideMode.offsetEnd:
      final end = resolveSlideIndex(
        meta: meta,
        curriculumDay: curriculumDay,
        slideCount: slideCount,
      );
      return MathSlideRange(start: 1, end: end);
  }
}
