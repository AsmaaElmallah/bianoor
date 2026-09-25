import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../curriculum/data/curriculum_cloud_repository.dart';
import '../../curriculum/data/progress_sync_service.dart';
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
  return VisualProgressStorage(ref.watch(prefsServiceProvider));
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
    final day = storage.curriculumDayFromStart(progress);
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

  /// [lessonNumber] overrides the current lesson (used when reviewing a completed day).
  Future<List<VisualRoundStep>> buildRoundSteps({int? lessonNumber}) async {
    final state = await future;
    final lesson = lessonNumber ?? state.lessonRange.lessonNumber;

    // Cloud-first: published slides from admin only (no local as source of truth).
    final cloud = await ref
        .read(curriculumCloudRepositoryProvider)
        .fetchPublished('visual');
    if (cloud.isNotEmpty) {
      final forLesson = cloud.where((s) => s.lessonNumber == lesson).toList();
      final use = forLesson.isNotEmpty ? forLesson : cloud;
      return [
        for (var i = 0; i < use.length; i++)
          VisualRoundStep(
            slide: VisualSlide(
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

    await ref.read(progressSyncServiceProvider).pushTrack(
          trackId: 'visual',
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
