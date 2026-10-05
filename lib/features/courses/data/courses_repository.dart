import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/course.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return const CoursesRepository();
});

/// Published courses only — RLS hides drafts.
final coursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(coursesRepositoryProvider).fetchCourses();
});

final courseLessonsProvider = FutureProvider.family<List<CourseLesson>, String>((ref, courseId) {
  return ref.watch(coursesRepositoryProvider).fetchLessons(courseId);
});

/// Server-side check (free / active subscription / enrollment).
final courseAccessProvider = FutureProvider.family<bool, String>((ref, courseId) {
  return ref.watch(coursesRepositoryProvider).hasAccess(courseId);
});

final courseProgressProvider =
    FutureProvider.family<Map<String, LessonProgress>, String>((ref, courseId) {
  return ref.watch(coursesRepositoryProvider).fetchProgress(courseId);
});

class CoursesRepository {
  const CoursesRepository();

  static const _bucket = 'course-videos';

  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  String? get _userId => SupabaseBootstrap.client.auth.currentUser?.id;

  Future<List<Course>> fetchCourses() async {
    if (!await _ready()) return const [];
    final rows = await SupabaseBootstrap.client
        .from('courses')
        .select('*, course_lessons(count)')
        .eq('publish_status', 'published')
        .order('sort_order')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List).map(Course.fromRow).toList();
  }

  Future<List<CourseLesson>> fetchLessons(String courseId) async {
    if (!await _ready()) return const [];
    final rows = await SupabaseBootstrap.client
        .from('course_lessons')
        .select()
        .eq('course_id', courseId)
        .eq('publish_status', 'published')
        .order('sort_order')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List).map(CourseLesson.fromRow).toList();
  }

  Future<bool> hasAccess(String courseId) async {
    if (!await _ready() || _userId == null) return false;
    try {
      final result = await SupabaseBootstrap.client
          .rpc('has_course_access', params: {'p_course_id': courseId});
      return result == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Courses] access check failed: $e');
      return false;
    }
  }

  Future<Map<String, LessonProgress>> fetchProgress(String courseId) async {
    final userId = _userId;
    if (!await _ready() || userId == null) return const {};
    try {
      final rows = await SupabaseBootstrap.client
          .from('course_lesson_progress')
          .select('lesson_id, position_seconds, completed')
          .eq('user_id', userId)
          .eq('course_id', courseId);
      return {
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          row['lesson_id'] as String: LessonProgress.fromRow(row),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('[Courses] progress fetch failed: $e');
      return const {};
    }
  }

  Future<void> saveProgress({
    required CourseLesson lesson,
    required int positionSeconds,
    required bool completed,
  }) async {
    final userId = _userId;
    if (!await _ready() || userId == null) return;
    try {
      await SupabaseBootstrap.client.from('course_lesson_progress').upsert({
        'user_id': userId,
        'lesson_id': lesson.id,
        'course_id': lesson.courseId,
        'position_seconds': positionSeconds < 0 ? 0 : positionSeconds,
        'completed': completed,
      }, onConflict: 'user_id,lesson_id');
    } catch (e) {
      if (kDebugMode) debugPrint('[Courses] progress save failed: $e');
    }
  }

  /// Short-lived link; storage policy only signs it when the user has access.
  Future<String?> signedVideoUrl(CourseLesson lesson) async {
    final path = lesson.videoPath;
    if (path == null || path.isEmpty || !await _ready()) return null;
    try {
      return await SupabaseBootstrap.client.storage.from(_bucket).createSignedUrl(path, 3 * 3600);
    } catch (e) {
      if (kDebugMode) debugPrint('[Courses] signed url failed: $e');
      return null;
    }
  }
}
