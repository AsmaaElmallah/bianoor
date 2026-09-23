import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/storage/prefs_service.dart';
import '../../curriculum/data/curriculum_cloud_repository.dart';
import '../../curriculum/data/progress_sync_service.dart';
import '../data/math_manifest.dart';
import '../data/math_progress_storage.dart';
import '../domain/math_curriculum_schedule.dart';
import '../domain/math_day_schedule.dart';
import '../domain/math_progress.dart';
import '../domain/math_slide.dart';

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
    final lesson = state.lessonRange.lessonNumber;

    // Cloud-first: published slides from admin only (no local as source of truth).
    final cloud = await ref
        .read(curriculumCloudRepositoryProvider)
        .fetchPublished('math');
    if (cloud.isNotEmpty) {
      final forLesson = cloud.where((s) => s.lessonNumber == lesson).toList();
      final use = forLesson.isNotEmpty ? forLesson : cloud;
      return [
        for (var i = 0; i < use.length; i++)
          MathRoundStep(
            trackLabel: use[i].title ?? 'سحابة',
            slide: MathSlide(
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
            slideIndexInTrack: i + 1,
            totalSlidesInTrack: use.length,
          ),
      ];
    }

    // No published cloud content yet.
    return [];
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

    await ref.read(progressSyncServiceProvider).pushTrack(
          trackId: 'math',
          curriculumDay: day,
          lessonNumber: current.lessonRange.lessonNumber,
          metadata: {
            'rounds_completed_today': updated.roundsCompletedToday,
          },
        );
    AppAnalytics.lessonComplete('math');
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
