import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/content_providers.dart';
import '../../auth/application/auth_session_provider.dart';
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
  return MathProgressStorage(
    ref.watch(prefsServiceProvider),
    ref.watch(userProgressSyncProvider),
  );
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
    final day = storage.effectiveCurriculumDay(progress);
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

  Future<List<MathRoundStep>> buildRoundSteps({int? lessonNumberOverride}) async {
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

    final range = lessonNumberOverride != null
        ? mathLessonSlideRange(lessonNumberOverride)
        : state.lessonRange;
    final start = range.globalStart;
    final end = range.globalEnd.clamp(start, sequence.length);
    if (end < start) return [];

    final repo = ref.read(mathManifestRepositoryProvider);
    final cloudSlides = await ref.read(curriculumSlidesRepositoryProvider).slidesForTrack('math');
    if (kDebugMode) {
      debugPrint('[Math] cloud slides published: ${cloudSlides.length}');
    }
    var cloudUsed = 0;
    final steps = <MathRoundStep>[];
    final totalInLesson = end - start + 1;

    for (var global = start; global <= end; global++) {
      final cloud = cloudSlides[global];
      MathSlide? slide;
      if (cloud != null && cloud.isPlayable) {
        slide = cloud.toMathSlide();
        cloudUsed += 1;
      } else {
        final slideRef = sequence[global - 1];
        slide = await repo.buildSlide(
          manifest: manifest,
          packageId: slideRef.packageId,
          slideIndex: slideRef.slideIndex,
        );
      }
      if (slide == null) continue;

      final pkgId = cloud?.packageId ?? sequence[global - 1].packageId;
      steps.add(
        MathRoundStep(
          trackLabel: mathTrackLabelForPackage(pkgId),
          slide: slide,
          slideIndexInTrack: steps.length + 1,
          totalSlidesInTrack: totalInLesson,
        ),
      );
    }

    if (kDebugMode) {
      debugPrint('[Math] round uses $cloudUsed/${steps.length} slides from Supabase');
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
    if (ref.read(prefsServiceProvider).isDevUnlockAllLessons()) return true;
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
