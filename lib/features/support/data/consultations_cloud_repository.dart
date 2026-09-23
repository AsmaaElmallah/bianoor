import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

final consultationsCloudRepositoryProvider =
    Provider<ConsultationsCloudRepository>((ref) {
  return ConsultationsCloudRepository();
});

final myConsultationRequestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(consultationsCloudRepositoryProvider).fetchMyRequests();
});

class ConsultationsCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<bool> submitRequest({
    required String topic,
    String? details,
  }) async {
    if (!await _ready()) return false;
    try {
      final userId = SupabaseBootstrap.client.auth.currentUser?.id;
      await SupabaseBootstrap.client.from('consultation_requests').insert({
        'user_id': userId,
        'topic': topic,
        'details': details,
      });
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Consultations] submit failed: $e\n$st');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyRequests() async {
    if (!await _ready()) return [];
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('consultation_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Consultations] list failed: $e\n$st');
      return [];
    }
  }
}
