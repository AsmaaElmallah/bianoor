import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/community_faq_data.dart';
import 'community_faq_remote_data_source.dart';

class CommunityFaqRepository {
  const CommunityFaqRepository({CommunityFaqRemoteDataSource? remote})
      : _remote = remote ?? const CommunityFaqRemoteDataSource();

  final CommunityFaqRemoteDataSource _remote;

  Future<List<CommunityFaqItem>> loadItems() async {
    if (!SupabaseBootstrap.isEnabled) {
      return List<CommunityFaqItem>.from(communityFaqItems);
    }

    try {
      final rows = await _remote.fetchPublished();
      if (rows.isEmpty) {
        return List<CommunityFaqItem>.from(communityFaqItems);
      }
      return rows
          .map(
            (r) => CommunityFaqItem(
              question: r['question'] as String? ?? '',
              answer: r['answer'] as String? ?? '',
            ),
          )
          .where((i) => i.question.isNotEmpty)
          .toList();
    } catch (e, st) {
      if (kDebugMode) debugPrint('[CommunityFaq] fetch failed: $e\n$st');
      return List<CommunityFaqItem>.from(communityFaqItems);
    }
  }
}
