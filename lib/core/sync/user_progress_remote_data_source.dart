import '../supabase/supabase_bootstrap.dart';

class UserProgressRemoteDataSource {
  const UserProgressRemoteDataSource();

  static const _table = 'user_learning_progress';

  Future<Map<String, dynamic>?> fetchForUser(String userId) async {
    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }

    final row = await SupabaseBootstrap.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<void> upsert(Map<String, dynamic> row) async {
    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }

    await SupabaseBootstrap.client.from(_table).upsert(row);
  }
}
