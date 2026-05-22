import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../data/math_manifest.dart';
import '../data/math_progress_storage.dart';
import '../domain/math_curriculum_schedule.dart';
import '../domain/math_day_schedule.dart';
import '../domain/math_progress.dart';
import '../domain/math_slide.dart';
import '../domain/math_track.dart';

final mathManifestRepositoryProvider = Provider<MathManifestRepository>((ref) {
  return MathManifestRepository();
});

final mathProgressStorageProvider = Provider<MathProgressStorage>((ref) {
  return MathProgressStorage(ref.watch(prefsServiceProvider));
});

class MathCurriculumState {
  const MathCurriculumState({
    required this.progress,
    required this.curriculumDay,
    required this.rules,
    required this.lessonRange,
    required this.manifestLoaded,
    this.manifest,
  });

  final MathProgress progress;
  final int curriculumDay;
  final MathDayRules rules;
  final MathLessonSlideRange lessonRange;
  final bool manifestLoaded;
  final MathManifest? manifest;

  MathCurriculumState copyWith({
    MathProgress? progress,
    int? curriculumDay,
    MathDayRules? rules,
    MathLessonSlideRange? lessonRange,
    bool? manifestLoaded,
    MathManifest? manifest,
  }) {
    return MathCurriculumState(
      progress: progress ?? this.progress,
      curriculumDay: curriculumDay ?? this.curriculumDay,
      rules: rules ?? this.rules,
      lessonRange: lessonRange ?? this.lessonRange,
      manifestLoaded: manifestLoaded ?? this.manifestLoaded,
      manifest: manifest ?? this.manifest,
    );
  }

  bool get canStartToday {
    if (!rules.isTrainingDay || rules.repetitionsPerDay <= 0) return false;
    final reps = rules.repetitionsPerDay;
    return progress.roundsCompletedToday < reps ||
        progress.lastSessionDateIso !=
            DateTime.now().toIso8601String().split('T').first;
  }
}

class MathCurriculumNotifier extends AsyncNotifier<MathCurriculumState> {
  @override
  Future<MathCurriculumState> build() async {
    final storage = ref.read(mathProgressStorageProvider);
    final manifestRepo = ref.read(mathManifestRepositoryProvider);

    var progress = await storage.ensureProgramStart();
    final day = storage.curriculumDayFromStart(progress);
    if (progress.curriculumDay != day) {
      progress = progress.copyWith(curriculumDay: day);
      await storage.save(progress);
    }

    final manifest = await manifestRepo.load();
    return MathCurriculumState(
      progress: progress,
      curriculumDay: day,
      rules: mathRulesForDay(day),
      lessonRange: mathLessonSlideRangeForDay(day),
      manifestLoaded: true,
      manifest: manifest,
    );
  }

  Future<List<MathRoundStep>> buildRoundSteps() async {
    final state = await future;
    final manifest = state.manifest;
    if (manifest == null) return [];

    final pkg129 = manifest.packageById(mathCorePackageIds[0]);
    final pkg133 = manifest.packageById(mathCorePackageIds[1]);
    final pkgBeads = manifest.packageById(mathCorePackageIds[2]);
    if (pkg129 == null || pkg133 == null || pkgBeads == null) return [];

    final sequence = buildMathGlobalSlideSequence(
      ppt129SlideCount: pkg129.slideCount,
      ppt133SlideCount: pkg133.slideCount,
      beadsSlideCount: pkgBeads.slideCount,
    );
    if (sequence.isEmpty) return [];

    final range = state.lessonRange;
    final start = range.globalStart;
    final end = range.globalEnd.clamp(start, sequence.length);
    if (end < start) return [];

    final repo = ref.read(mathManifestRepositoryProvider);
    final steps = <MathRoundStep>[];
    final totalInLesson = end - start + 1;

    for (var global = start; global <= end; global++) {
      final ref = sequence[global - 1];
      final slide = await repo.buildSlide(
        manifest: manifest,
        packageId: ref.packageId,
        slideIndex: ref.slideIndex,
      );
      if (slide == null) continue;

      steps.add(
        MathRoundStep(
          trackLabel: mathTrackLabelForPackage(ref.packageId),
          slide: slide,
          slideIndexInTrack: steps.length + 1,
          totalSlidesInTrack: totalInLesson,
        ),
      );
    }

    return steps;
  }

  Future<void> completeRound() async {
    final storage = ref.read(mathProgressStorageProvider);
    final current = state.value;
    if (current == null) return;

    final updated = await storage.completeRound(current.progress);
    final day = current.curriculumDay;
    state = AsyncData(
      current.copyWith(
        progress: updated,
        rules: mathRulesForDay(day),
        lessonRange: mathLessonSlideRangeForDay(day),
      ),
    );
  }

  bool canStartAnotherRoundToday() {
    final current = state.value;
    if (current == null) return false;
    if (!current.rules.isTrainingDay || current.rules.repetitionsPerDay <= 0) {
      return false;
    }
    final storage = ref.read(mathProgressStorageProvider);
    return storage.canStartAnotherRoundToday(
      current.progress,
      current.rules.repetitionsPerDay,
    );
  }
}

final mathCurriculumProvider =
    AsyncNotifierProvider<MathCurriculumNotifier, MathCurriculumState>(
  MathCurriculumNotifier.new,
);
