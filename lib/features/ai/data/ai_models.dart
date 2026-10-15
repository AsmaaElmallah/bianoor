import 'package:flutter/foundation.dart';

/// Replaces the `{{baby}}` placeholder the AI uses instead of the real name.
String withBabyName(String text, String? babyName) {
  final name = (babyName ?? '').trim();
  return text.replaceAll('{{baby}}', name.isEmpty ? 'طفلك' : name);
}

class AiSource {
  const AiSource({required this.title, this.url});

  final String title;
  final String? url;

  static List<AiSource> listFrom(dynamic raw) => [
        if (raw is List)
          for (final s in raw)
            if (s is Map && (s['title'] ?? '').toString().isNotEmpty)
              AiSource(title: s['title'].toString(), url: s['url']?.toString()),
      ];
}

class AiActivity {
  const AiActivity({required this.title, required this.steps});

  final String title;
  final List<String> steps;
}

class AiMessage {
  const AiMessage({
    required this.id,
    required this.isUser,
    required this.isEmergency,
    required this.content,
    required this.payload,
    required this.createdAt,
  });

  factory AiMessage.fromRow(Map<String, dynamic> row) {
    return AiMessage(
      id: row['id'] as String,
      isUser: row['role'] == 'user',
      isEmergency: row['kind'] == 'emergency',
      content: row['content'] as String? ?? '',
      payload: row['payload'] is Map ? Map<String, dynamic>.from(row['payload'] as Map) : const {},
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  factory AiMessage.pendingUser(String text) => AiMessage(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        isUser: true,
        isEmergency: false,
        content: text,
        payload: const {},
        createdAt: DateTime.now(),
      );

  /// The answer while it is still being written.
  factory AiMessage.streaming() => AiMessage(
        id: '$streamingPrefix${DateTime.now().microsecondsSinceEpoch}',
        isUser: false,
        isEmergency: false,
        content: '',
        payload: const {'format': 'md'},
        createdAt: DateTime.now(),
      );

  static const streamingPrefix = 'stream_';

  /// A partial answer that stopped streaming (stopped or connection lost); kept on screen only.
  AiMessage asCut() => AiMessage(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        isUser: false,
        isEmergency: false,
        content: content,
        payload: {...payload, 'cut': true},
        createdAt: createdAt,
      );

  AiMessage copyWith({String? content, Map<String, dynamic>? payload}) => AiMessage(
        id: id,
        isUser: isUser,
        isEmergency: isEmergency,
        content: content ?? this.content,
        payload: payload ?? this.payload,
        createdAt: createdAt,
      );

  final String id;
  final bool isUser;
  final bool isEmergency;
  final String content;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  bool get isLocal => id.startsWith('local_');

  bool get isStreaming => id.startsWith(streamingPrefix);

  /// Free-form markdown answer (new style); older answers are structured cards.
  bool get isMarkdown => payload['format'] == 'md';

  /// Red steps shown above an answer whose question looked like an emergency.
  Map<String, dynamic>? get emergency =>
      payload['emergency'] is Map ? Map<String, dynamic>.from(payload['emergency'] as Map) : null;

  String get summary => (payload['summary'] as String?)?.trim().isNotEmpty == true
      ? payload['summary'] as String
      : content;

  AiActivity? get activity {
    final raw = payload['activity'];
    if (raw is! Map) return null;
    final steps = [for (final s in (raw['steps'] as List? ?? const [])) s.toString()];
    final title = raw['title']?.toString() ?? '';
    if (title.isEmpty || steps.isEmpty) return null;
    return AiActivity(title: title, steps: steps);
  }

  String get seeDoctorWhen => payload['see_doctor_when']?.toString().trim() ?? '';

  List<String> get followups => [for (final f in (payload['followups'] as List? ?? const [])) f.toString()];

  List<AiSource> get sources => AiSource.listFrom(payload['sources']);

  bool get grounded => payload['grounded'] == true;

  /// Fixed safety lines added by the server (meal answers).
  List<String> get notes => [for (final n in (payload['notes'] as List? ?? const [])) n.toString()];

  String get emergencyTitle => payload['title']?.toString() ?? 'ده موقف طارئ';

  List<String> get emergencySteps => [for (final s in (payload['steps'] as List? ?? const [])) s.toString()];
}

class AiPlanActivity {
  const AiPlanActivity({required this.title, required this.minutes, required this.why, required this.steps});

  final String title;
  final int minutes;
  final String why;
  final List<String> steps;
}

class AiDailyPlan {
  const AiDailyPlan({
    required this.tip,
    required this.activities,
    required this.quranMoment,
    required this.sources,
  });

  factory AiDailyPlan.fromJson(Map<String, dynamic> json) {
    return AiDailyPlan(
      tip: json['tip']?.toString() ?? '',
      quranMoment: json['quran_moment']?.toString() ?? '',
      sources: AiSource.listFrom(json['sources']),
      activities: [
        for (final a in (json['activities'] as List? ?? const []))
          if (a is Map)
            AiPlanActivity(
              title: a['title']?.toString() ?? '',
              minutes: (a['minutes'] as num?)?.toInt() ?? 5,
              why: a['why']?.toString() ?? '',
              steps: [for (final s in (a['steps'] as List? ?? const [])) s.toString()],
            ),
      ],
    );
  }

  final String tip;
  final List<AiPlanActivity> activities;
  final String quranMoment;
  final List<AiSource> sources;
}

/// Server answer states other than a normal reply.
enum AiStatus { ok, emergency, limit, busy, disabled, notConfigured, error }

AiStatus aiStatusFrom(String? raw) => switch (raw) {
      'ok' => AiStatus.ok,
      'emergency' => AiStatus.emergency,
      'limit' => AiStatus.limit,
      'busy' => AiStatus.busy,
      'disabled' => AiStatus.disabled,
      'not_configured' => AiStatus.notConfigured,
      _ => AiStatus.error,
    };

String aiStatusMessage(AiStatus status) => switch (status) {
      AiStatus.limit => 'خلصتي أسئلة النهارده 💛 تقدري تسألي تاني بكرة، أو تحجزي استشارة مع أخصائية بيانور.',
      AiStatus.busy => 'المساعدة مشغولة دلوقتي من كتر الأسئلة، جربي كمان شوية.',
      AiStatus.disabled => 'المساعدة متوقفة مؤقتاً من فريق بيانور.',
      AiStatus.notConfigured => 'المساعدة لسه بتتجهز، جربي بعدين.',
      _ => 'حصلت مشكلة في الاتصال، جربي تاني.',
    };

/// Status text for the mother; in debug builds the server reason is appended.
String aiStatusText(AiStatus status, String? detail) {
  final text = aiStatusMessage(status);
  return kDebugMode && detail != null && detail.isNotEmpty ? '$text\n($detail)' : text;
}

enum AiStreamEventType { meta, delta, done, failed }

/// One event of a streamed answer: [meta] first, then [delta]s, then [done] or [failed].
class AiStreamEvent {
  const AiStreamEvent._(
    this.type, {
    this.text = '',
    this.conversationId,
    this.emergency,
    this.message,
    this.status = AiStatus.ok,
    this.detail,
  });

  const AiStreamEvent.meta({String? conversationId, Map<String, dynamic>? emergency})
      : this._(AiStreamEventType.meta, conversationId: conversationId, emergency: emergency);

  const AiStreamEvent.delta(String text) : this._(AiStreamEventType.delta, text: text);

  const AiStreamEvent.done({String? conversationId, required AiMessage message})
      : this._(AiStreamEventType.done, conversationId: conversationId, message: message);

  const AiStreamEvent.failed(AiStatus status, {String? conversationId, String? detail})
      : this._(AiStreamEventType.failed, status: status, conversationId: conversationId, detail: detail);

  final AiStreamEventType type;
  final String text;
  final String? conversationId;
  final Map<String, dynamic>? emergency;
  final AiMessage? message;
  final AiStatus status;
  final String? detail;
}

class AiMealRequest {
  const AiMealRequest({required this.ingredients, required this.allergies});

  final String ingredients;
  final List<String> allergies;
}

class AiPlanResult {
  const AiPlanResult({required this.status, this.plan, this.detail});

  final AiStatus status;
  final AiDailyPlan? plan;
  final String? detail;
}

class AiSettings {
  const AiSettings({required this.enabled});

  final bool enabled;
}
