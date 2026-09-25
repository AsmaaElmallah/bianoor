import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../curriculum/data/curriculum_cloud_repository.dart';
import '../../curriculum/data/progress_sync_service.dart';
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
  return EmotionalProgressStorage(ref.watch(prefsServiceProvider));
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
    final day = storage.curriculumDayFromStart(progress);
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

  /// [lessonNumber] overrides the current lesson (used when reviewing a completed day).
  Future<List<EmotionalRoundStep>> buildRoundSteps({int? lessonNumber}) async {
    final state = await future;
    final lesson = lessonNumber ?? state.lessonRange.lessonNumber;

    // Cloud-first: published slides from admin only (no local as source of truth).
    final cloud = await ref
        .read(curriculumCloudRepositoryProvider)
        .fetchPublished('emotional');
    if (cloud.isNotEmpty) {
      final forLesson = cloud.where((s) => s.lessonNumber == lesson).toList();
      final use = forLesson.isNotEmpty ? forLesson : cloud;
      return [
        for (var i = 0; i < use.length; i++)
          EmotionalRoundStep(
            slide: EmotionalSlide(
              packageId: use[i].packageId ?? 'cloud',
              slideIndex: use[i].slideIndex,
              assetFolder: '',
              durationSec: use[i].durationSec.toDouble(),
              imageAssets: const [],
              imageUrls: [
                if (use[i].imageUrl != null && use[i].imageUrl!.isNotEmpty)
                  use[i].imageUrl!,
              ],
              audioUrl: use[i].audioUrl,
            ),
            slideIndexInLesson: i + 1,
            totalSlidesInLesson: use.length,
          ),
      ];
    }

    // No published cloud content yet.
    return [];
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

    await ref.read(progressSyncServiceProvider).pushTrack(
          trackId: 'emotional',
          curriculumDay: day,
          lessonNumber: current.lessonRange.lessonNumber,
          metadata: {
            'rounds_completed_today': updated.roundsCompletedToday,
          },
        );
  }

  bool canStartAnotherRoundToday() {
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
