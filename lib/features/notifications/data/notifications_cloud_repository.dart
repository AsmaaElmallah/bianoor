import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

class CloudNotification {
  const CloudNotification({
    required this.id,
    required this.title,
    required this.body,
    this.sentAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? sentAt;
}

final notificationsCloudRepositoryProvider =
    Provider<NotificationsCloudRepository>((ref) {
  return NotificationsCloudRepository();
});

final sentNotificationsProvider = FutureProvider<List<CloudNotification>>((ref) {
  return ref.watch(notificationsCloudRepositoryProvider).fetchSent();
});

class NotificationsCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<List<CloudNotification>> fetchSent() async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('notification_campaigns')
          .select()
          .eq('status', 'sent')
          .order('sent_at', ascending: false);

      return [
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          CloudNotification(
            id: row['id'] as String,
            title: row['title'] as String? ?? '',
            body: row['body'] as String? ?? '',
            sentAt: row['sent_at'] != null
                ? DateTime.tryParse(row['sent_at'] as String)
                : null,
          ),
      ];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Notifications] fetch failed: $e\n$st');
      return [];
    }
  }

  /// Registers/updates FCM-like device token for the signed-in user.
  Future<bool> upsertDeviceToken({
    required String token,
    String platform = 'android',
  }) async {
    if (!await _ready()) return false;
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await SupabaseBootstrap.client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
        },
        onConflict: 'user_id,token',
      );
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Notifications] token upsert failed: $e\n$st');
      return false;
    }
  }
}
