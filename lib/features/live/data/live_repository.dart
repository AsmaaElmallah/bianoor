import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/live_session.dart';

final liveRepositoryProvider = Provider<LiveRepository>((ref) => const LiveRepository());

final liveSessionsProvider = FutureProvider<List<LiveSession>>((ref) {
  return ref.watch(liveRepositoryProvider).fetchSessions();
});

final liveAccessProvider = FutureProvider.family<bool, String>((ref, sessionId) {
  return ref.watch(liveRepositoryProvider).hasAccess(sessionId);
});

class LiveException implements Exception {
  const LiveException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LiveRepository {
  const LiveRepository();

  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  SupabaseClient get _client => SupabaseBootstrap.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<LiveSession>> fetchSessions() async {
    if (!await _ready()) return const [];
    final rows = await _client
        .from('live_sessions')
        .select()
        .eq('publish_status', 'published')
        .order('scheduled_at', ascending: true, nullsFirst: false);
    return List<Map<String, dynamic>>.from(rows as List).map(LiveSession.fromRow).toList();
  }

  Future<bool> hasAccess(String sessionId) async {
    if (!await _ready() || _userId == null) return false;
    try {
      final res = await _client.rpc('has_live_access', params: {'p_session_id': sessionId});
      return res == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Live] access check failed: $e');
      return false;
    }
  }

  Future<LivePass> fetchPass(String sessionId) async {
    if (!await _ready()) throw const LiveException('الخدمة غير متاحة حالياً');
    if (_userId == null) throw const LiveException('سجّلي دخولك الأول');
    try {
      final res = await _client.functions.invoke('live-token', body: {'session_id': sessionId});
      return LivePass.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on FunctionException catch (e) {
      if (kDebugMode) debugPrint('[Live] token failed: ${e.status} ${e.details}');
      final code = e.details is Map ? (e.details as Map)['error'] : null;
      throw LiveException(switch (code) {
        'not_live' => 'اللايف لسه ما بدأش',
        'no_access' => 'اللايف ده مش متاح لحسابك',
        'agora_not_configured' => 'اللايف مش جاهز لسه، حاولي بعد شوية',
        _ => 'تعذّر الدخول للايف، حاولي تاني',
      });
    }
  }

  Future<String> _displayName() async {
    final user = _client.auth.currentUser;
    try {
      final row = await _client.from('profiles').select('display_name').eq('id', user!.id).maybeSingle();
      final name = (row?['display_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return user?.email?.split('@').first ?? 'أم';
  }

  Future<void> raiseHand(String sessionId) async {
    final userId = _userId;
    if (userId == null) throw const LiveException('سجّلي دخولك الأول');
    await _client.from('live_stage_requests').upsert({
      'session_id': sessionId,
      'user_id': userId,
      'display_name': await _displayName(),
      'status': 'pending',
    }, onConflict: 'session_id,user_id');
  }

  Future<void> leaveStage(String sessionId) async {
    final userId = _userId;
    if (userId == null) return;
    await _client
        .from('live_stage_requests')
        .update({'status': 'left'})
        .eq('session_id', sessionId)
        .eq('user_id', userId);
  }

  /// My stage request status for this session ('pending', 'approved', ...) or null.
  Stream<String?> watchMyStageStatus(String sessionId) {
    final userId = _userId;
    return _client
        .from('live_stage_requests')
        .stream(primaryKey: ['session_id', 'user_id'])
        .eq('session_id', sessionId)
        .map((rows) {
          for (final row in rows) {
            if (row['user_id'] == userId) return row['status'] as String?;
          }
          return null;
        });
  }

  Stream<LiveStatus> watchStatus(String sessionId) {
    return _client
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((rows) => rows.isEmpty ? LiveStatus.ended : LiveStatus.fromDb(rows.first['status'] as String?));
  }
}
