import 'dart:convert';
import 'dart:io';

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

  /// Always returns a map with at least `status`; failures carry a `detail` for debugging.
  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    Map<String, dynamic> fail(String detail) {
      if (kDebugMode) debugPrint('[AI] ${body['action']} failed: $detail');
      return {'status': 'error', 'detail': detail};
    }

    if (!await _ready()) return fail('Supabase not ready');
    if (_userId == null) return fail('not signed in');
    try {
      final res = await SupabaseBootstrap.client.functions.invoke(_function, body: body);
      if (res.data is! Map) return fail('bad response: ${res.data}');
      final data = Map<String, dynamic>.from(res.data as Map);
      if (kDebugMode && data['detail'] != null) debugPrint('[AI] ${body['action']}: ${data['status']} ${data['detail']}');
      return data;
    } on FunctionException catch (e) {
      return fail('http ${e.status}: ${e.details}');
    } catch (e) {
      return fail('$e');
    }
  }

  /// Streams the answer as it is written. The SDK's `functions.invoke` waits for the whole body,
  /// so this talks to the edge function over raw HTTP and reads the server-sent events.
  Stream<AiStreamEvent> askStream({
    required String question,
    String? conversationId,
    required int ageRangeIndex,
    AiMealRequest? meal,
  }) async* {
    AiStreamEvent fail(String detail, [AiStatus status = AiStatus.error]) {
      if (kDebugMode) debugPrint('[AI] ask failed: $detail');
      return AiStreamEvent.failed(status, conversationId: conversationId, detail: detail);
    }

    if (!await _ready()) {
      yield fail('Supabase not ready');
      return;
    }
    final auth = SupabaseBootstrap.client.auth;
    var session = auth.currentSession;
    if (session == null) {
      yield fail('not signed in');
      return;
    }
    if (session.isExpired) {
      try {
        session = (await auth.refreshSession()).session ?? session;
      } catch (_) {}
    }

    final http = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await http.postUrl(Uri.parse('${SupabaseBootstrap.url}/functions/v1/$_function'));
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${session!.accessToken}')
        ..set('apikey', SupabaseBootstrap.anonKey)
        ..contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode({
        'action': 'ask',
        'question': question,
        if (conversationId != null) 'conversation_id': conversationId,
        'age_range_index': ageRangeIndex,
        if (meal != null) ...{
          'mode': 'meal',
          'meal': {'ingredients': meal.ingredients, 'allergies': meal.allergies},
        },
      })));
      final response = await request.close();

      // Limits, «disabled» and auth errors come back as a plain JSON body, not a stream.
      if (response.headers.contentType?.mimeType != 'text/event-stream') {
        final raw = await response.transform(utf8.decoder).join();
        final data = raw.isEmpty ? const {} : jsonDecode(raw);
        final map = data is Map ? data : const {};
        yield AiStreamEvent.failed(
          aiStatusFrom(map['status'] as String?),
          conversationId: map['conversation_id'] as String? ?? conversationId,
          detail: map['detail']?.toString() ?? (response.statusCode >= 400 ? 'http ${response.statusCode}: $raw' : null),
        );
        return;
      }

      var finished = false;
      await for (final line in response.transform(utf8.decoder).transform(const LineSplitter())) {
        if (!line.startsWith('data:')) continue;
        final event = jsonDecode(line.substring(5).trim());
        if (event is! Map) continue;
        final id = event['conversation_id'] as String?;
        switch (event['t']) {
          case 'meta':
            final emergency = event['emergency'];
            yield AiStreamEvent.meta(
              conversationId: id,
              emergency: emergency is Map ? Map<String, dynamic>.from(emergency) : null,
            );
          case 'delta':
            yield AiStreamEvent.delta(event['text'] as String? ?? '');
          case 'done':
            finished = true;
            yield AiStreamEvent.done(
              conversationId: id,
              message: AiMessage.fromRow(Map<String, dynamic>.from(event['message'] as Map)),
            );
          case 'error':
            finished = true;
            if (kDebugMode) debugPrint('[AI] ask: ${event['status']} ${event['detail']}');
            yield AiStreamEvent.failed(
              aiStatusFrom(event['status'] as String?),
              conversationId: id,
              detail: event['detail']?.toString(),
            );
        }
      }
      if (!finished) yield fail('stream closed early');
    } catch (e) {
      yield fail('$e');
    } finally {
      http.close();
    }
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
    final status = aiStatusFrom(data['status'] as String?);
    final plan = data['plan'];
    return AiPlanResult(
      status: status,
      plan: plan is Map ? AiDailyPlan.fromJson(Map<String, dynamic>.from(plan)) : null,
      detail: data['detail']?.toString(),
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
    if (!await _ready()) return const AiSettings(enabled: false);
    try {
      final row = await SupabaseBootstrap.client
          .from('app_settings')
          .select('value')
          .eq('key', 'ai_enabled')
          .maybeSingle();
      return AiSettings(enabled: row?['value'] != 'false');
    } catch (_) {
      return const AiSettings(enabled: true);
    }
  }
}
