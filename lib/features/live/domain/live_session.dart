enum LiveStatus {
  scheduled,
  live,
  ended;

  static LiveStatus fromDb(String? value) => switch (value) {
        'live' => LiveStatus.live,
        'ended' => LiveStatus.ended,
        _ => LiveStatus.scheduled,
      };
}

enum LiveAccessType {
  free,
  subscription,
  course;

  static LiveAccessType fromDb(String? value) => switch (value) {
        'free' => LiveAccessType.free,
        'course' => LiveAccessType.course,
        _ => LiveAccessType.subscription,
      };
}

class LiveSession {
  const LiveSession({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorName,
    required this.accessType,
    required this.status,
    this.coverUrl,
    this.courseId,
    this.scheduledAt,
    this.recordingYoutubeId,
  });

  final String id;
  final String title;
  final String description;
  final String instructorName;
  final String? coverUrl;
  final LiveAccessType accessType;
  final String? courseId;
  final DateTime? scheduledAt;
  final LiveStatus status;
  final String? recordingYoutubeId;

  bool get hasRecording => recordingYoutubeId?.isNotEmpty ?? false;

  String? get scheduleLabel {
    final at = scheduledAt?.toLocal();
    if (at == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final period = at.hour < 12 ? 'ص' : 'م';
    return '${at.day}/${at.month} — ${two(hour)}:${two(at.minute)} $period';
  }

  factory LiveSession.fromRow(Map<String, dynamic> row) {
    final at = row['scheduled_at'] as String?;
    return LiveSession(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      instructorName: row['instructor_name'] as String? ?? '',
      coverUrl: row['cover_url'] as String?,
      accessType: LiveAccessType.fromDb(row['access_type'] as String?),
      courseId: row['course_id'] as String?,
      scheduledAt: at != null ? DateTime.tryParse(at) : null,
      status: LiveStatus.fromDb(row['status'] as String?),
      recordingYoutubeId: row['recording_youtube_id'] as String?,
    );
  }
}

/// What the live-token function returns: everything needed to join the Agora channel.
class LivePass {
  const LivePass({
    required this.appId,
    required this.channel,
    required this.account,
    required this.role,
    this.token,
  });

  final String appId;
  final String channel;
  final String account;
  final String role;

  /// Null when the Agora project runs in testing mode (no certificate).
  final String? token;

  bool get canSpeak => role == 'speaker' || role == 'host';

  factory LivePass.fromJson(Map<String, dynamic> json) => LivePass(
        appId: json['app_id'] as String,
        channel: json['channel'] as String,
        account: json['account'] as String,
        role: json['role'] as String,
        token: json['token'] as String?,
      );
}
