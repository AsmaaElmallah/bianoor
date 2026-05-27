import '../../../core/supabase/supabase_bootstrap.dart';

class CommunityFaqRemoteDataSource {
  const CommunityFaqRemoteDataSource();

  Future<List<Map<String, dynamic>>> fetchPublished() async {
    if (!SupabaseBootstrap.isEnabled) return [];
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    final rows = await SupabaseBootstrap.client
        .from('community_faq_items')
        .select()
        .eq('publish_status', 'published')
        .order('sort_order');

    return List<Map<String, dynamic>>.from(rows as List);
  }
}
