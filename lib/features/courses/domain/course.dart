import '../../payments/domain/payment_item.dart';

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
    this.priceUsd,
    this.categoryLabel = '',
    this.instructorTitle = '',
    this.instructorAvatarUrl,
    this.oldPriceLabel = '',
    this.promoNote = '',
    this.guaranteeNote = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String instructorName;
  final String instructorTitle;
  final String? instructorAvatarUrl;
  final String categoryLabel;
  final String oldPriceLabel;
  final String promoNote;
  final String guaranteeNote;
  final String? coverUrl;
  final CourseAccessType accessType;
  final String priceLabel;
  final int lessonCount;
  final String? storeProductIdAndroid;
  final String? storeProductIdIos;
  final double? priceUsd;

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
      priceUsd: parseUsd(row['price_usd']),
      categoryLabel: row['category_label'] as String? ?? '',
      instructorTitle: row['instructor_title'] as String? ?? '',
      instructorAvatarUrl: _nonEmpty(row['instructor_avatar_url']),
      oldPriceLabel: row['old_price_label'] as String? ?? '',
      promoNote: row['promo_note'] as String? ?? '',
      guaranteeNote: row['guarantee_note'] as String? ?? '',
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
    this.unitTitle = '',
    this.liveSessionId,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final String unitTitle;

  /// Set when the lesson is a recording of a live session.
  final String? liveSessionId;
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
      unitTitle: (row['unit_title'] as String? ?? '').trim(),
      liveSessionId: row['live_session_id'] as String?,
    );
  }
}

/// A downloadable course file (PDF) stored in the private «course-files» bucket.
class CourseResource {
  const CourseResource({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.filePath,
    required this.isPreview,
  });

  final String id;
  final String title;
  final String subtitle;
  final String filePath;
  final bool isPreview;

  factory CourseResource.fromRow(Map<String, dynamic> row) {
    return CourseResource(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      subtitle: row['subtitle'] as String? ?? '',
      filePath: row['file_path'] as String,
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
