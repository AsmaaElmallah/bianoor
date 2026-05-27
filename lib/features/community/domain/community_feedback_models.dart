enum CommunityFeedbackKind { complaint, suggestion }

class CommunityFeedbackTicket {
  const CommunityFeedbackTicket({
    required this.id,
    required this.kind,
    required this.subject,
    required this.body,
    required this.boardStatus,
    required this.createdAt,
    required this.updatedAt,
    this.adminReply,
  });

  final String id;
  final String kind;
  final String subject;
  final String body;
  final String boardStatus;
  final String? adminReply;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isComplaint => kind == 'complaint';
  bool get hasAdminReply =>
      adminReply != null && adminReply!.trim().isNotEmpty;

  String get statusLabel {
    switch (boardStatus) {
      case 'in_review':
        return 'قيد المراجعة';
      case 'replied':
        return 'تم الرد';
      case 'closed':
        return 'مغلق';
      case 'new':
      default:
        return 'جديد';
    }
  }

  factory CommunityFeedbackTicket.fromJson(Map<String, dynamic> json) {
    return CommunityFeedbackTicket(
      id: json['id'] as String,
      kind: json['kind'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      boardStatus: json['board_status'] as String? ?? 'new',
      adminReply: json['admin_reply'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
