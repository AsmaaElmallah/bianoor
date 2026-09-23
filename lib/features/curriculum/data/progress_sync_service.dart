import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../curriculum/data/lesson_progress_cloud_repository.dart';
import '../../onboarding_questions/data/children_cloud_repository.dart';

final progressSyncServiceProvider = Provider<ProgressSyncService>((ref) {
  return ProgressSyncService(
    ref.watch(prefsServiceProvider),
    ref.watch(lessonProgressCloudRepositoryProvider),
    ref.watch(childrenCloudRepositoryProvider),
  );
});

/// Pulls cloud lesson progress into local prefs after login / app start.
class ProgressSyncService {
  ProgressSyncService(this._prefs, this._progress, this._children);

  final PrefsService _prefs;
  final LessonProgressCloudRepository _progress;
  final ChildrenCloudRepository _children;

  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady &&
        SupabaseBootstrap.client.auth.currentUser != null;
  }

  /// Pull remote progress + active child into prefs (cloud wins if newer).
  Future<void> pullAndMerge() async {
    if (!await _ready()) return;

    try {
      final child = await _children.fetchActiveChild();
      if (child != null) {
        await _prefs.setBabyName(child.name);
        await _prefs.setBabyAgeRangeIndex(child.ageRangeIndex);
        await _prefs.setActiveChildId(child.id);
        await _prefs.setOnboardingComplete(true);
      } else {
        // Clear stale device profile from a previous local account.
        await _prefs.setOnboardingComplete(false);
        await _prefs.setBabyName('');
      }

      for (final track in const ['math', 'visual', 'emotional', 'quran']) {
        final row = await _progress.fetchTrackProgress(track);
        if (row == null) continue;
        await _applyTrackRow(track, row);
      }

      if (kDebugMode) debugPrint('[ProgressSync] pullAndMerge done');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[ProgressSync] pull failed: $e\n$st');
    }
  }

  Future<void> pushTrack({
    required String trackId,
    int? curriculumDay,
    int? lessonNumber,
    Map<String, dynamic>? metadata,
  }) async {
    final childId = _prefs.getActiveChildId();
    await _progress.upsertTrackProgress(
      trackId: trackId,
      curriculumDay: curriculumDay,
      lessonNumber: lessonNumber,
      metadata: {
        ...?metadata,
        if (childId != null) 'child_id': childId,
      },
      childId: childId,
    );
  }

  Future<void> _applyTrackRow(String track, Map<String, dynamic> row) async {
    final day = row['curriculum_day'] as int?;
    final meta = row['metadata'];
    final Map<String, dynamic> metadata =
        meta is Map ? Map<String, dynamic>.from(meta) : {};

    switch (track) {
      case 'math':
        if (day != null) await _prefs.setMathCurriculumDay(day);
        final rounds = metadata['rounds_completed_today'];
        if (rounds is int) await _prefs.setMathRoundsCompletedToday(rounds);
        break;
      case 'visual':
        if (day != null) await _prefs.setVisualCurriculumDay(day);
        final rounds = metadata['rounds_completed_today'];
        if (rounds is int) await _prefs.setVisualRoundsCompletedToday(rounds);
        break;
      case 'emotional':
        if (day != null) await _prefs.setEmotionalCurriculumDay(day);
        final rounds = metadata['rounds_completed_today'];
        if (rounds is int) {
          await _prefs.setEmotionalRoundsCompletedToday(rounds);
        }
        break;
      case 'quran':
        final khatmah = metadata['khatmah_index'];
        final session = metadata['session_index'];
        if (khatmah is int) await _prefs.setQuranKhatmahIndex(khatmah);
        if (session is int) await _prefs.setQuranSessionIndex(session);
        break;
    }
  }
}
