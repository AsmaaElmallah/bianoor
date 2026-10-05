enum CourseAccessType {
  free,
  subscription,
  paid;

  static CourseAccessType fromDb(String? value) {
    switch (value) {
      case 'subscription':
        return CourseAccessType.subscription;
      case 'paid':
        return CourseAccessType.paid;
      default:
        return CourseAccessType.free;
    }
  }
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.instructorName,
    required this.accessType,
    required this.priceLabel,
    this.coverUrl,
    this.lessonCount = 0,
    this.storeProductIdAndroid,
    this.storeProductIdIos,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String instructorName;
  final String? coverUrl;
  final CourseAccessType accessType;
  final String priceLabel;
  final int lessonCount;
  final String? storeProductIdAndroid;
  final String? storeProductIdIos;

  String get accessLabel {
    switch (accessType) {
      case CourseAccessType.free:
        return 'مجانية';
      case CourseAccessType.subscription:
        return 'ضمن الباقة';
      case CourseAccessType.paid:
        return priceLabel.isNotEmpty ? priceLabel : 'مدفوعة';
    }
  }

  factory Course.fromRow(Map<String, dynamic> row) {
    final lessons = row['course_lessons'];
    var count = 0;
    if (lessons is List && lessons.isNotEmpty) {
      count = (lessons.first as Map)['count'] as int? ?? 0;
    }
    return Course(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      subtitle: row['subtitle'] as String? ?? '',
      description: row['description'] as String? ?? '',
      instructorName: row['instructor_name'] as String? ?? '',
      coverUrl: row['cover_url'] as String?,
      accessType: CourseAccessType.fromDb(row['access_type'] as String?),
      priceLabel: row['price_label'] as String? ?? '',
      lessonCount: count,
      storeProductIdAndroid: _nonEmpty(row['store_product_id_android']),
      storeProductIdIos: _nonEmpty(row['store_product_id_ios']),
    );
  }
}

String? _nonEmpty(Object? value) {
  final s = (value as String?)?.trim();
  return s == null || s.isEmpty ? null : s;
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.isPreview,
    this.videoPath,
    this.youtubeVideoId,
    this.durationSeconds,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final String? videoPath;
  final String? youtubeVideoId;
  final int? durationSeconds;
  final bool isPreview;

  bool get isYoutube => (videoPath == null || videoPath!.isEmpty) && (youtubeVideoId?.isNotEmpty ?? false);

  String? get durationLabel {
    final s = durationSeconds;
    if (s == null || s <= 0) return null;
    final minutes = (s / 60).round();
    return minutes < 1 ? 'أقل من دقيقة' : '$minutes دقيقة';
  }

  factory CourseLesson.fromRow(Map<String, dynamic> row) {
    return CourseLesson(
      id: row['id'] as String,
      courseId: row['course_id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      videoPath: row['video_path'] as String?,
      youtubeVideoId: row['youtube_video_id'] as String?,
      durationSeconds: row['duration_seconds'] as int?,
      isPreview: row['is_preview'] as bool? ?? false,
    );
  }
}

class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.positionSeconds,
    required this.completed,
  });

  final String lessonId;
  final int positionSeconds;
  final bool completed;

  factory LessonProgress.fromRow(Map<String, dynamic> row) {
    return LessonProgress(
      lessonId: row['lesson_id'] as String,
      positionSeconds: row['position_seconds'] as int? ?? 0,
      completed: row['completed'] as bool? ?? false,
    );
  }
}
