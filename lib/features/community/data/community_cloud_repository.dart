import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/community_faq_data.dart';

class MothersClubCategory {
  const MothersClubCategory({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

class MothersClubPost {
  const MothersClubPost({
    required this.id,
    required this.title,
    required this.body,
    this.authorDisplayName,
    this.tag,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? authorDisplayName;
  final String? tag;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;
}

final communityCloudRepositoryProvider = Provider<CommunityCloudRepository>((ref) {
  return CommunityCloudRepository();
});

final myCommunityFeedbackProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, kind) {
  return ref
      .watch(communityCloudRepositoryProvider)
      .fetchMyFeedback(kind: kind);
});

final publishedFaqProvider = FutureProvider<List<CommunityFaqItem>>((ref) {
  return ref.watch(communityCloudRepositoryProvider).fetchPublishedFaq();
});

final mothersClubCategoriesProvider =
    FutureProvider<List<MothersClubCategory>>((ref) {
  return ref.watch(communityCloudRepositoryProvider).fetchClubCategories();
});

final mothersClubPostsProvider = FutureProvider<List<MothersClubPost>>((ref) {
  return ref.watch(communityCloudRepositoryProvider).fetchPublishedClubPosts();
});

class CommunityCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<List<CommunityFaqItem>> fetchPublishedFaq() async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('community_faq')
          .select()
          .eq('publish_status', 'published')
          .order('sort_order');
      return [
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          CommunityFaqItem(
            question: row['question'] as String? ?? '',
            answer: row['answer'] as String? ?? '',
          ),
      ];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] FAQ failed: $e\n$st');
      return [];
    }
  }

  Future<bool> submitFeedback({
    required String kind,
    required String subject,
    required String body,
  }) async {
    if (!await _ready()) return false;
    try {
      final userId = SupabaseBootstrap.client.auth.currentUser?.id;
      await SupabaseBootstrap.client.from('community_feedback').insert({
        'user_id': userId,
        'kind': kind,
        'subject': subject,
        'body': body,
      });
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] feedback failed: $e\n$st');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyFeedback({String? kind}) async {
    if (!await _ready()) return [];
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      var q = SupabaseBootstrap.client
          .from('community_feedback')
          .select()
          .eq('user_id', userId);
      if (kind != null) q = q.eq('kind', kind);
      final rows = await q.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] my feedback failed: $e\n$st');
      return [];
    }
  }

  Future<List<MothersClubCategory>> fetchClubCategories() async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('mothers_club_categories')
          .select()
          .eq('publish_status', 'published')
          .order('sort_order');
      return [
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          MothersClubCategory(
            id: row['id'] as String,
            title: row['title'] as String? ?? '',
          ),
      ];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] categories failed: $e\n$st');
      return [];
    }
  }

  Future<List<MothersClubPost>> fetchPublishedClubPosts() async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('mothers_club_posts')
          .select()
          .eq('publish_status', 'published')
          .order('created_at', ascending: false);
      return [
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          MothersClubPost(
            id: row['id'] as String,
            title: row['title'] as String? ?? '',
            body: row['body'] as String? ?? '',
            authorDisplayName: row['author_display_name'] as String?,
            tag: row['tag'] as String?,
            likesCount: (row['likes_count'] as int?) ?? 0,
            commentsCount: (row['comments_count'] as int?) ?? 0,
            createdAt: row['created_at'] != null
                ? DateTime.tryParse(row['created_at'] as String)
                : null,
          ),
      ];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] posts failed: $e\n$st');
      return [];
    }
  }
}
