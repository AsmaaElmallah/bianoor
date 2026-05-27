import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/content/content_fetch_result.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/mothers_club_mock_data.dart';
import '../domain/mothers_club_models.dart';
import 'mothers_club_remote_data_source.dart';

class MothersClubPostsPage {
  const MothersClubPostsPage({
    required this.posts,
    required this.source,
    required this.hasMore,
    this.errorMessage,
    this.remoteCount,
  });

  final List<MothersClubPost> posts;
  final ContentFetchSource source;
  final bool hasMore;
  final String? errorMessage;
  final int? remoteCount;
}

class MothersClubRepository {
  const MothersClubRepository({MothersClubRemoteDataSource? remote})
      : _remote = remote ?? const MothersClubRemoteDataSource();

  final MothersClubRemoteDataSource _remote;

  Future<ContentFetchResult<List<MothersClubCategory>>> loadCategories() async {
    if (!SupabaseBootstrap.isEnabled) {
      return ContentFetchResult(
        data: localMothersClubCategories(),
        source: ContentFetchSource.supabaseDisabled,
      );
    }

    try {
      final rows = await _remote.fetchPublishedCategories();
      if (rows.isEmpty) {
        return ContentFetchResult(
          data: localMothersClubCategories(),
          source: ContentFetchSource.remoteEmpty,
        );
      }
      return ContentFetchResult(
        data: rows.map(MothersClubCategory.fromMap).toList(),
        source: ContentFetchSource.remote,
        remoteCount: rows.length,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[MothersClub] categories failed: $e\n$st');
      return ContentFetchResult(
        data: localMothersClubCategories(),
        source: ContentFetchSource.errorFallback,
        errorMessage: e.toString(),
      );
    }
  }

  static const pageSize = 15;

  Future<MothersClubPostsPage> loadPostsPage({
    String? categoryId,
    String? userId,
    int offset = 0,
    int limit = pageSize,
  }) async {
    if (!SupabaseBootstrap.isEnabled) {
      return MothersClubPostsPage(
        posts: _filterLocalPosts(categoryId),
        source: ContentFetchSource.supabaseDisabled,
        hasMore: false,
      );
    }

    try {
      final rows = await _remote.fetchPublishedPosts(
        categoryId: categoryId,
        limit: limit,
        offset: offset,
      );
      Set<String> likedIds = {};
      if (userId != null) {
        likedIds = await _remote.fetchMyLikedPostIds(userId);
      }

      if (rows.isEmpty && offset == 0) {
        return MothersClubPostsPage(
          posts: _filterLocalPosts(categoryId),
          source: ContentFetchSource.remoteEmpty,
          hasMore: false,
        );
      }

      final posts = rows
          .map(
            (row) => MothersClubPost.fromMap(
              row,
              likedByMe: likedIds.contains(row['id']),
            ),
          )
          .toList();

      return MothersClubPostsPage(
        posts: posts,
        source: ContentFetchSource.remote,
        hasMore: rows.length >= limit,
        remoteCount: rows.length,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[MothersClub] posts page failed: $e\n$st');
      if (offset == 0) {
        return MothersClubPostsPage(
          posts: _filterLocalPosts(categoryId),
          source: ContentFetchSource.errorFallback,
          hasMore: false,
          errorMessage: e.toString(),
        );
      }
      rethrow;
    }
  }

  Future<ContentFetchResult<List<MothersClubPost>>> loadPosts({
    String? categoryId,
    String? userId,
  }) async {
    final page = await loadPostsPage(categoryId: categoryId, userId: userId);
    return ContentFetchResult(
      data: page.posts,
      source: page.source,
      remoteCount: page.remoteCount,
      errorMessage: page.errorMessage,
    );
  }

  Future<MothersClubPost?> loadPostById(String postId, {String? userId}) async {
    if (!SupabaseBootstrap.isEnabled) {
      try {
        return localMothersClubPosts().firstWhere((p) => p.id == postId);
      } catch (_) {
        return null;
      }
    }

    try {
      final row = await _remote.fetchPostById(postId);
      if (row == null) return null;
      var liked = false;
      if (userId != null) {
        final ids = await _remote.fetchMyLikedPostIds(userId);
        liked = ids.contains(postId);
      }
      return MothersClubPost.fromMap(row, likedByMe: liked);
    } catch (e) {
      if (kDebugMode) debugPrint('[MothersClub] post by id failed: $e');
      return null;
    }
  }

  Future<List<MothersClubComment>> loadComments(String postId) async {
    if (!SupabaseBootstrap.isEnabled) return [];

    try {
      final rows = await _remote.fetchComments(postId);
      return rows.map(MothersClubComment.fromMap).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[MothersClub] comments failed: $e');
      return [];
    }
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool currentlyLiked,
  }) {
    return _remote.toggleLike(
      postId: postId,
      userId: userId,
      liked: currentlyLiked,
    );
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String authorDisplayName,
    required String body,
  }) {
    return _remote.addComment(
      postId: postId,
      userId: userId,
      authorDisplayName: authorDisplayName,
      body: body,
    );
  }

  Future<void> createPost({
    required String userId,
    required String authorDisplayName,
    required String title,
    required String body,
    String? tag,
    String? categoryId,
    Uint8List? imageBytes,
    String? imageExtension,
    String? imageContentType,
  }) async {
    if (!SupabaseBootstrap.isEnabled) {
      throw StateError('Supabase غير مفعّل — تحققي من dart_defines.json');
    }
    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }

    String? imagePath;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        imagePath = await _remote
            .uploadPostImage(
              userId: userId,
              bytes: imageBytes,
              extension: imageExtension ?? 'jpg',
              contentType: imageContentType ?? 'image/jpeg',
            )
            .timeout(const Duration(seconds: 45));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[MothersClub] image upload failed, posting text only: $e');
        }
      }
    }

    await _remote
        .createPost(
          userId: userId,
          authorDisplayName: authorDisplayName,
          title: title,
          body: body,
          tag: tag,
          categoryId: categoryId,
          imageStoragePath: imagePath,
        )
        .timeout(const Duration(seconds: 30));
  }

  List<MothersClubPost> _filterLocalPosts(String? categoryId) {
    final all = localMothersClubPosts();
    if (categoryId == null || categoryId.isEmpty) return all;
    return all.where((p) => p.categoryId == categoryId).toList();
  }
}
