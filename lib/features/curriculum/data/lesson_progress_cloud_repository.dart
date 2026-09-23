import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

final lessonProgressCloudRepositoryProvider =
    Provider<LessonProgressCloudRepository>((ref) {
  return LessonProgressCloudRepository();
});

/// Syncs local curriculum day progress to Supabase when the user is signed in.
class LessonProgressCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<void> upsertTrackProgress({
    required String trackId,
    int? curriculumDay,
    int? lessonNumber,
    Map<String, dynamic>? metadata,
    String? childId,
  }) async {
    if (!await _ready()) return;
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseBootstrap.client.from('lesson_progress').upsert(
        {
          'user_id': userId,
          'track_id': trackId,
          'curriculum_day': curriculumDay,
          'lesson_number': lessonNumber,
          'metadata': metadata ?? {},
          if (childId != null) 'child_id': childId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,track_id',
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Progress] upsert $trackId failed: $e\n$st');
    }
  }

  Future<Map<String, dynamic>?> fetchTrackProgress(String trackId) async {
    if (!await _ready()) return null;
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      return await SupabaseBootstrap.client
          .from('lesson_progress')
          .select()
          .eq('user_id', userId)
          .eq('track_id', trackId)
          .maybeSingle();
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Progress] fetch $trackId failed: $e\n$st');
      return null;
    }
  }
}
