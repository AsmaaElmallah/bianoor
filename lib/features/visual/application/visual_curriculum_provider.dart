import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/content_providers.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../../core/storage/prefs_service.dart';
import '../../curriculum/domain/curriculum_day_rules.dart';
import '../data/visual_manifest.dart';
import '../data/visual_progress_storage.dart';
import '../domain/visual_curriculum_schedule.dart';
import '../domain/visual_progress.dart';
import '../domain/visual_slide.dart';

final visualManifestRepositoryProvider = Provider<VisualManifestRepository>((ref) {
  return VisualManifestRepository();
});

final visualProgressStorageProvider = Provider<VisualProgressStorage>((ref) {
  return VisualProgressStorage(
    ref.watch(prefsServiceProvider),
    ref.watch(userProgressSyncProvider),
  );
});

class VisualCurriculumState {
  const VisualCurriculumState({
    required this.progress,
    required this.curriculumDay,
    required this.rules,
    required this.lessonRange,
    required this.manifestLoaded,
    this.manifest,
  });

  final VisualProgress progress;
  final int curriculumDay;
  final CurriculumDayRules rules;
  final VisualLessonSlideRange lessonRange;
  final bool manifestLoaded;
  final VisualManifest? manifest;

  VisualCurriculumState copyWith({
    VisualProgress? progress,
    int? curriculumDay,
    CurriculumDayRules? rules,
    VisualLessonSlideRange? lessonRange,
    bool? manifestLoaded,
    VisualManifest? manifest,
  }) {
    return VisualCurriculumState(
      progress: progress ?? this.progress,
      curriculumDay: curriculumDay ?? this.curriculumDay,
      rules: rules ?? this.rules,
      lessonRange: lessonRange ?? this.lessonRange,
      manifestLoaded: manifestLoaded ?? this.manifestLoaded,
      manifest: manifest ?? this.manifest,
    );
  }
}

class VisualCurriculumNotifier extends AsyncNotifier<VisualCurriculumState> {
  @override
  Future<VisualCurriculumState> build() async {
    final storage = ref.read(visualProgressStorageProvider);
    final manifestRepo = ref.read(visualManifestRepositoryProvider);

    var progress = await storage.ensureProgramStart();
    final day = storage.effectiveCurriculumDay(progress);
    if (progress.curriculumDay != day) {
      progress = progress.copyWith(curriculumDay: day);
      await storage.save(progress);
    }

    final manifest = await manifestRepo.load();
    return VisualCurriculumState(
      progress: progress,
      curriculumDay: day,
      rules: curriculumRulesForDay(day, lastNewContentDay: visualLastNewContentDay),
      lessonRange: visualLessonSlideRangeForDay(day),
      manifestLoaded: true,
      manifest: manifest,
    );
  }

  Future<List<VisualRoundStep>> buildRoundSteps({int? lessonNumberOverride}) async {
    final state = await future;
    final manifest = state.manifest;
    if (manifest == null) return [];

    final counts = <String, int>{};
    for (final id in visualSourcePackageIds) {
      counts[id] = manifest.packageById(id)?.slideCount ?? 0;
    }

    final sequence = buildVisualGlobalSlideSequence(counts);
    if (sequence.isEmpty) return [];

    final range = lessonNumberOverride != null
        ? visualLessonSlideRange(lessonNumberOverride)
        : state.lessonRange;
    final start = range.globalStart;
    final end = range.globalEnd.clamp(start, sequence.length);
    if (end < start) return [];

    final repo = ref.read(visualManifestRepositoryProvider);
    final cloudSlides = await ref.read(curriculumSlidesRepositoryProvider).slidesForTrack('visual');
    if (kDebugMode) {
      debugPrint('[Visual] cloud slides published: ${cloudSlides.length}');
    }
    var cloudUsed = 0;
    final steps = <VisualRoundStep>[];
    final totalInLesson = end - start + 1;

    for (var global = start; global <= end; global++) {
      final cloud = cloudSlides[global];
      VisualSlide? slide;
      if (cloud != null && cloud.isPlayable) {
        slide = cloud.toVisualSlide();
        cloudUsed += 1;
      } else {
        final refSlide = sequence[global - 1];
        slide = await repo.buildSlide(
          manifest: manifest,
          packageId: refSlide.packageId,
          slideIndex: refSlide.slideIndex,
        );
      }
      if (slide == null) continue;

      steps.add(
        VisualRoundStep(
          slide: slide,
          slideIndexInLesson: steps.length + 1,
          totalSlidesInLesson: totalInLesson,
        ),
      );
    }

    if (kDebugMode) {
      debugPrint('[Visual] round uses $cloudUsed/${steps.length} slides from Supabase');
    }
    return steps;
  }

  Future<void> completeRound() async {
    final current = state.value;
    if (current == null) return;

    final storage = ref.read(visualProgressStorageProvider);
    final updated = await storage.completeRound(current.progress);
    final day = current.curriculumDay;
    state = AsyncData(
      current.copyWith(
        progress: updated,
        rules: curriculumRulesForDay(day, lastNewContentDay: visualLastNewContentDay),
        lessonRange: visualLessonSlideRangeForDay(day),
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
    final storage = ref.read(visualProgressStorageProvider);
    return storage.canStartAnotherRoundToday(
      current.progress,
      current.rules.repetitionsPerDay,
    );
  }
}

final visualCurriculumProvider =
    AsyncNotifierProvider<VisualCurriculumNotifier, VisualCurriculumState>(
  VisualCurriculumNotifier.new,
);
