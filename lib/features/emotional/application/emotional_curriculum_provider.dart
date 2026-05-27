import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/content_providers.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../../core/storage/prefs_service.dart';
import '../../curriculum/domain/curriculum_day_rules.dart';
import '../data/emotional_manifest.dart';
import '../data/emotional_progress_storage.dart';
import '../domain/emotional_curriculum_schedule.dart';
import '../domain/emotional_progress.dart';
import '../domain/emotional_slide.dart';

final emotionalManifestRepositoryProvider = Provider<EmotionalManifestRepository>((ref) {
  return EmotionalManifestRepository();
});

final emotionalProgressStorageProvider = Provider<EmotionalProgressStorage>((ref) {
  return EmotionalProgressStorage(
    ref.watch(prefsServiceProvider),
    ref.watch(userProgressSyncProvider),
  );
});

class EmotionalCurriculumState {
  const EmotionalCurriculumState({
    required this.progress,
    required this.curriculumDay,
    required this.rules,
    required this.lessonRange,
    required this.manifestLoaded,
    this.manifest,
  });

  final EmotionalProgress progress;
  final int curriculumDay;
  final CurriculumDayRules rules;
  final EmotionalLessonSlideRange lessonRange;
  final bool manifestLoaded;
  final EmotionalManifest? manifest;

  EmotionalCurriculumState copyWith({
    EmotionalProgress? progress,
    int? curriculumDay,
    CurriculumDayRules? rules,
    EmotionalLessonSlideRange? lessonRange,
    bool? manifestLoaded,
    EmotionalManifest? manifest,
  }) {
    return EmotionalCurriculumState(
      progress: progress ?? this.progress,
      curriculumDay: curriculumDay ?? this.curriculumDay,
      rules: rules ?? this.rules,
      lessonRange: lessonRange ?? this.lessonRange,
      manifestLoaded: manifestLoaded ?? this.manifestLoaded,
      manifest: manifest ?? this.manifest,
    );
  }
}

class EmotionalCurriculumNotifier extends AsyncNotifier<EmotionalCurriculumState> {
  @override
  Future<EmotionalCurriculumState> build() async {
    final storage = ref.read(emotionalProgressStorageProvider);
    final manifestRepo = ref.read(emotionalManifestRepositoryProvider);

    var progress = await storage.ensureProgramStart();
    final day = storage.effectiveCurriculumDay(progress);
    if (progress.curriculumDay != day) {
      progress = progress.copyWith(curriculumDay: day);
      await storage.save(progress);
    }

    final manifest = await manifestRepo.load();
    return EmotionalCurriculumState(
      progress: progress,
      curriculumDay: day,
      rules: curriculumRulesForDay(day, lastNewContentDay: emotionalLastNewContentDay),
      lessonRange: emotionalLessonSlideRangeForDay(day),
      manifestLoaded: true,
      manifest: manifest,
    );
  }

  Future<List<EmotionalRoundStep>> buildRoundSteps({int? lessonNumberOverride}) async {
    final state = await future;
    final manifest = state.manifest;
    if (manifest == null) return [];

    final counts = <String, int>{};
    for (final id in emotionalSourcePackageIds) {
      counts[id] = manifest.packageById(id)?.slideCount ?? 0;
    }

    final sequence = buildEmotionalGlobalSlideSequence(counts);
    if (sequence.isEmpty) return [];

    final range = lessonNumberOverride != null
        ? emotionalLessonSlideRange(lessonNumberOverride)
        : state.lessonRange;
    final start = range.globalStart;
    final end = range.globalEnd.clamp(start, sequence.length);
    if (end < start) return [];

    final repo = ref.read(emotionalManifestRepositoryProvider);
    final cloudSlides =
        await ref.read(curriculumSlidesRepositoryProvider).slidesForTrack('emotional');
    if (kDebugMode) {
      debugPrint('[Emotional] cloud slides published: ${cloudSlides.length}');
    }
    var cloudUsed = 0;
    final steps = <EmotionalRoundStep>[];
    final totalInLesson = end - start + 1;

    for (var global = start; global <= end; global++) {
      final cloud = cloudSlides[global];
      EmotionalSlide? slide;
      if (cloud != null && cloud.isPlayable) {
        slide = cloud.toEmotionalSlide();
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
        EmotionalRoundStep(
          slide: slide,
          slideIndexInLesson: steps.length + 1,
          totalSlidesInLesson: totalInLesson,
        ),
      );
    }

    if (kDebugMode) {
      debugPrint('[Emotional] round uses $cloudUsed/${steps.length} slides from Supabase');
    }
    return steps;
  }

  Future<void> completeRound() async {
    final current = state.value;
    if (current == null) return;

    final storage = ref.read(emotionalProgressStorageProvider);
    final updated = await storage.completeRound(current.progress);
    final day = current.curriculumDay;
    state = AsyncData(
      current.copyWith(
        progress: updated,
        rules: curriculumRulesForDay(day, lastNewContentDay: emotionalLastNewContentDay),
        lessonRange: emotionalLessonSlideRangeForDay(day),
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
    final storage = ref.read(emotionalProgressStorageProvider);
    return storage.canStartAnotherRoundToday(
      current.progress,
      current.rules.repetitionsPerDay,
    );
  }
}

final emotionalCurriculumProvider =
    AsyncNotifierProvider<EmotionalCurriculumNotifier, EmotionalCurriculumState>(
  EmotionalCurriculumNotifier.new,
);
