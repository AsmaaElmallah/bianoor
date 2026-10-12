import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import 'ai_models.dart';

const _function = 'ai-assistant';

final aiRepositoryProvider = Provider<AiRepository>((ref) => AiRepository());

class AiRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  String? get _userId => SupabaseBootstrap.isReady ? SupabaseBootstrap.client.auth.currentUser?.id : null;

  Future<Map<String, dynamic>?> _invoke(Map<String, dynamic> body) async {
    if (!await _ready()) return null;
    try {
      final res = await SupabaseBootstrap.client.functions.invoke(_function, body: body);
      return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
    } on FunctionException catch (e) {
      if (kDebugMode) debugPrint('[AI] ${body['action']} failed: ${e.status} ${e.details}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[AI] ${body['action']} failed: $e');
      return null;
    }
  }

  Future<AiAskResult> ask({
    required String question,
    String? conversationId,
    required int ageRangeIndex,
    AiMealRequest? meal,
  }) async {
    final data = await _invoke({
      'action': 'ask',
      'question': question,
      if (conversationId != null) 'conversation_id': conversationId,
      'age_range_index': ageRangeIndex,
      if (meal != null) ...{
        'mode': 'meal',
        'meal': {'ingredients': meal.ingredients, 'allergies': meal.allergies},
      },
    });
    if (data == null) return const AiAskResult(status: AiStatus.error);
    final message = data['message'];
    return AiAskResult(
      status: aiStatusFrom(data['status'] as String?),
      conversationId: data['conversation_id'] as String?,
      message: message is Map ? AiMessage.fromRow(Map<String, dynamic>.from(message)) : null,
    );
  }

  Future<AiPlanResult> fetchTodayPlan({required int ageRangeIndex, required String lang}) async {
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final data = await _invoke({
      'action': 'daily_plan',
      'date': date,
      'age_range_index': ageRangeIndex,
      'lang': lang,
    });
    if (data == null) return const AiPlanResult(status: AiStatus.error);
    final status = aiStatusFrom(data['status'] as String?);
    final plan = data['plan'];
    return AiPlanResult(
      status: status,
      plan: plan is Map ? AiDailyPlan.fromJson(Map<String, dynamic>.from(plan)) : null,
    );
  }

  Future<String?> latestConversationId() async {
    if (!await _ready() || _userId == null) return null;
    final row = await SupabaseBootstrap.client
        .from('ai_conversations')
        .select('id')
        .eq('user_id', _userId!)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<List<AiMessage>> fetchMessages(String conversationId) async {
    if (!await _ready()) return [];
    final rows = await SupabaseBootstrap.client
        .from('ai_messages')
        .select('id, role, kind, content, payload, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at')
        .limit(200);
    return [for (final r in List<Map<String, dynamic>>.from(rows as List)) AiMessage.fromRow(r)];
  }

  Future<Map<String, int>> fetchMyRatings(List<String> messageIds) async {
    if (messageIds.isEmpty || !await _ready()) return {};
    final rows = await SupabaseBootstrap.client
        .from('ai_feedback')
        .select('message_id, rating')
        .inFilter('message_id', messageIds);
    return {
      for (final r in List<Map<String, dynamic>>.from(rows as List))
        r['message_id'] as String: (r['rating'] as num).toInt(),
    };
  }

  Future<void> rate(String messageId, int rating, {String? reason}) async {
    if (!await _ready() || _userId == null) return;
    await SupabaseBootstrap.client.from('ai_feedback').upsert(
      {
        'message_id': messageId,
        'user_id': _userId,
        'rating': rating,
        'reason': reason,
      },
      onConflict: 'message_id,user_id',
    );
  }

  Future<AiSettings> fetchSettings() async {
    if (!await _ready()) return const AiSettings(enabled: false, emergencyPhone: '');
    try {
      final rows = await SupabaseBootstrap.client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', ['ai_enabled', 'ai_emergency_phone']);
      final map = {
        for (final r in List<Map<String, dynamic>>.from(rows as List)) r['key'] as String: r['value'] as String? ?? '',
      };
      return AiSettings(
        enabled: map['ai_enabled'] != 'false',
        emergencyPhone: (map['ai_emergency_phone'] ?? '').trim(),
      );
    } catch (_) {
      return const AiSettings(enabled: true, emergencyPhone: '');
    }
  }
}
