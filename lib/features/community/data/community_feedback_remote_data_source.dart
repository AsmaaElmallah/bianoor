import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/community_feedback_models.dart';

class CommunityFeedbackRemoteDataSource {
  const CommunityFeedbackRemoteDataSource();

  Future<void> submit({
    required String kind,
    required String subject,
    required String body,
    String? userId,
    String? authorDisplayName,
    String? childName,
    String? childAgeLabel,
  }) async {
    if (!SupabaseBootstrap.isEnabled) return;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    await SupabaseBootstrap.client.from('community_feedback').insert({
      'kind': kind,
      'user_id': userId,
      'author_display_name': authorDisplayName ?? 'مستخدمة بيانور',
      'subject': subject,
      'body': body,
      'child_name': childName,
      'child_age_label': childAgeLabel,
      'priority': 'medium',
      'board_status': 'new',
    });
  }

  Future<List<CommunityFeedbackTicket>> fetchMine({
    required String userId,
    String? kind,
  }) async {
    if (!SupabaseBootstrap.isEnabled) return [];
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    var builder = SupabaseBootstrap.client
        .from('community_feedback')
        .select()
        .eq('user_id', userId);

    if (kind != null && kind.isNotEmpty) {
      builder = builder.eq('kind', kind);
    }

    final rows = await builder.order('created_at', ascending: false);

    return [
      for (final row in List<Map<String, dynamic>>.from(rows as List))
        CommunityFeedbackTicket.fromJson(row),
    ];
  }
}
