import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/community_feedback_models.dart';
import 'community_feedback_remote_data_source.dart';

class CommunityFeedbackRepository {
  const CommunityFeedbackRepository({CommunityFeedbackRemoteDataSource? remote})
      : _remote = remote ?? const CommunityFeedbackRemoteDataSource();

  final CommunityFeedbackRemoteDataSource _remote;

  Future<bool> submit({
    required bool isComplaint,
    required String subject,
    required String body,
    String? userId,
    String? authorDisplayName,
    String? childName,
    String? childAgeLabel,
  }) async {
    if (!SupabaseBootstrap.isEnabled) return false;

    try {
      await _remote.submit(
        kind: isComplaint ? 'complaint' : 'suggestion',
        subject: subject,
        body: body,
        userId: userId,
        authorDisplayName: authorDisplayName,
        childName: childName,
        childAgeLabel: childAgeLabel,
      );
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CommunityFeedback] submit failed: $e\n$st');
      }
      rethrow;
    }
  }

  Future<List<CommunityFeedbackTicket>> fetchMine({
    required String userId,
    String? kind,
  }) async {
    if (!SupabaseBootstrap.isEnabled) return [];

    try {
      return await _remote.fetchMine(userId: userId, kind: kind);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CommunityFeedback] fetchMine failed: $e\n$st');
      }
      return [];
    }
  }
}
