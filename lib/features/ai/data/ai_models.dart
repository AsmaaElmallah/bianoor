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

  final String id;
  final bool isUser;
  final bool isEmergency;
  final String content;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  bool get isLocal => id.startsWith('local_');

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

class AiAskResult {
  const AiAskResult({required this.status, this.conversationId, this.message});

  final AiStatus status;
  final String? conversationId;
  final AiMessage? message;
}

class AiMealRequest {
  const AiMealRequest({required this.ingredients, required this.allergies});

  final String ingredients;
  final List<String> allergies;
}

class AiPlanResult {
  const AiPlanResult({required this.status, this.plan});

  final AiStatus status;
  final AiDailyPlan? plan;
}

class AiSettings {
  const AiSettings({required this.enabled, required this.emergencyPhone});

  final bool enabled;
  final String emergencyPhone;
}
